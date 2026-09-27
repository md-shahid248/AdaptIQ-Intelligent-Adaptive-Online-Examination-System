package com.adaptiveexam.servlets;

import com.adaptiveexam.dao.*;
import com.adaptiveexam.models.*;
import com.adaptiveexam.util.AdaptiveEngine;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.*;

@WebServlet("/exam")
public class ExamServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
            return;
        }

        User student = (User) session.getAttribute("user");
        if (!"Student".equals(student.getRole())) {
            res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "start":       handleStart(req, res, session, student); break;
            case "answer":      handleAnswer(req, res, session, student); break;
            case "submit":      handleFinalize(req, res, session, student, "Completed"); break;
            case "autosubmit":  handleFinalize(req, res, session, student, "Auto-Submitted"); break;
            default:            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
        }
    }

    // ─────────────────────────────────────────────────────────────
    // START: initialise session state and load first question
    // ─────────────────────────────────────────────────────────────
    private void handleStart(HttpServletRequest req, HttpServletResponse res,
                             HttpSession session, User student)
            throws ServletException, IOException {

        int examId;
        try {
            examId = Integer.parseInt(req.getParameter("examId"));
        } catch (NumberFormatException e) {
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        // Check exam exists and is active
        Exam exam = new ExamDAO().getExamById(examId);
        if (exam == null || !exam.isActive()) {
            session.setAttribute("flash", "Exam is not available.");
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        // Create attempt record in DB
        AttemptDAO attemptDAO = new AttemptDAO();
        int attemptId = attemptDAO.createAttempt(student.getId(), examId);
        if (attemptId < 0) {
            session.setAttribute("flash", "Could not start exam. Please try again.");
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        // Initialise session state
        session.setAttribute("examId",          examId);
        session.setAttribute("attemptId",        attemptId);
        session.setAttribute("askedIds",         new ArrayList<Integer>());
        session.setAttribute("totalScore",       0.0);
        session.setAttribute("totalAnswered",    0);
        session.setAttribute("totalCorrect",     0);
        session.setAttribute("easyCount",        0);
        session.setAttribute("mediumCount",      0);
        session.setAttribute("hardCount",        0);
        session.setAttribute("currentDifficulty", AdaptiveEngine.getStartDifficulty());

        // Fetch first question (Medium)
        Question first = AdaptiveEngine.getNextQuestion(
                examId, AdaptiveEngine.getStartDifficulty(), new ArrayList<>());

        if (first == null) {
            session.setAttribute("flash", "This exam has no questions yet.");
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        session.setAttribute("currentQuestion", first);
        session.setAttribute("questionNumber",  1);
        session.setAttribute("examObj",         exam);

        req.getRequestDispatcher("/jsp/student/exam.jsp").forward(req, res);
    }

    // ─────────────────────────────────────────────────────────────
    // ANSWER: evaluate response, save to DB, fetch next question
    // ─────────────────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    private void handleAnswer(HttpServletRequest req, HttpServletResponse res,
                              HttpSession session, User student)
            throws ServletException, IOException {

        Question current = (Question) session.getAttribute("currentQuestion");
        if (current == null) {
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        int examId    = (int)    session.getAttribute("examId");
        int attemptId = (int)    session.getAttribute("attemptId");
        List<Integer> askedIds = (List<Integer>) session.getAttribute("askedIds");

        String selectedParam = req.getParameter("answer");
        char selected = (selectedParam != null && !selectedParam.isEmpty())
                        ? selectedParam.charAt(0) : '\0';
        boolean isCorrect = (selected == current.getCorrectAnswer());

        // Fetch marks for this question's difficulty
        Map<String, Double> marksMap = new ExamDAO().getDifficultyMarks(examId);
        double marks = isCorrect ? marksMap.getOrDefault(current.getDifficulty(), 1.0) : 0.0;

        // Save response to DB
        new AttemptDAO().saveResponse(attemptId, current.getId(), selected == '\0' ? '-' : selected,
                                      isCorrect, marks);

        // Update session counters
        double totalScore = (double) session.getAttribute("totalScore") + marks;
        int totalAnswered  = (int) session.getAttribute("totalAnswered") + 1;
        int totalCorrect   = (int) session.getAttribute("totalCorrect")  + (isCorrect ? 1 : 0);

        // Update difficulty distribution counters
        updateDifficultyCount(session, current.getDifficulty());

        session.setAttribute("totalScore",    totalScore);
        session.setAttribute("totalAnswered", totalAnswered);
        session.setAttribute("totalCorrect",  totalCorrect);

        askedIds.add(current.getId());

        // Check if exam should end (question limit reached)
        Exam exam = (Exam) session.getAttribute("examObj");
        if (askedIds.size() >= exam.getTotalQuestions()) {
            handleFinalize(req, res, session, student, "Completed");
            return;
        }

        // Determine next difficulty and fetch next question
        String nextDifficulty = AdaptiveEngine.determineNextDifficulty(
                current.getDifficulty(), isCorrect);
        Question next = AdaptiveEngine.getNextQuestion(examId, nextDifficulty, askedIds);

        if (next == null) {
            // No more questions available — finalize
            handleFinalize(req, res, session, student, "Completed");
            return;
        }

        session.setAttribute("currentQuestion",  next);
        session.setAttribute("currentDifficulty", next.getDifficulty());
        session.setAttribute("questionNumber",    totalAnswered + 1);

        req.getRequestDispatcher("/jsp/student/exam.jsp").forward(req, res);
    }

    // ─────────────────────────────────────────────────────────────
    // FINALIZE: save results and redirect to result page
    // ─────────────────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    private void handleFinalize(HttpServletRequest req, HttpServletResponse res,
                                HttpSession session, User student, String status)
            throws ServletException, IOException {

        Integer examIdObj    = (Integer) session.getAttribute("examId");
        Integer attemptIdObj = (Integer) session.getAttribute("attemptId");

        if (examIdObj == null || attemptIdObj == null) {
            res.sendRedirect(req.getContextPath() + "/jsp/student/dashboard.jsp");
            return;
        }

        int examId    = examIdObj;
        int attemptId = attemptIdObj;

        double totalScore   = (double) session.getAttribute("totalScore");
        int    totalAnswered = (int)   session.getAttribute("totalAnswered");
        int    totalCorrect  = (int)   session.getAttribute("totalCorrect");
        int    easyCount     = (int)   session.getAttribute("easyCount");
        int    mediumCount   = (int)   session.getAttribute("mediumCount");
        int    hardCount     = (int)   session.getAttribute("hardCount");

        double accuracy = totalAnswered > 0
                ? ((double) totalCorrect / totalAnswered) * 100.0 : 0.0;

        String difficultySummary = "Easy:" + easyCount + ",Medium:" + mediumCount + ",Hard:" + hardCount;

        // Compute max possible score (sum of Hard marks × total questions as upper bound)
        Map<String, Double> marksMap = new ExamDAO().getDifficultyMarks(examId);
        double maxPossible = marksMap.getOrDefault("Hard", 4.0) * totalAnswered;

        // Finalize attempt in DB
        new AttemptDAO().finalizeAttempt(attemptId, totalScore, accuracy, difficultySummary, status);

        // Save result
        new ResultDAO().saveResult(attemptId, student.getId(), examId, totalScore, maxPossible);

        // Clear exam session state
        clearExamSession(session);

        // Pass result data to result page
        req.setAttribute("score",       String.format("%.2f", totalScore));
        req.setAttribute("maxPossible", String.format("%.2f", maxPossible));
        req.setAttribute("accuracy",    String.format("%.1f", accuracy));
        req.setAttribute("totalAnswered", totalAnswered);
        req.setAttribute("totalCorrect",  totalCorrect);
        req.setAttribute("status",        status);
        req.setAttribute("attemptId",     attemptId);
        req.setAttribute("easyCount",     easyCount);
        req.setAttribute("mediumCount",   mediumCount);
        req.setAttribute("hardCount",     hardCount);

        req.getRequestDispatcher("/jsp/student/result.jsp").forward(req, res);
    }

    @SuppressWarnings("unchecked")
    private void updateDifficultyCount(HttpSession session, String difficulty) {
        switch (difficulty) {
            case "Easy":
                session.setAttribute("easyCount",   (int) session.getAttribute("easyCount") + 1); break;
            case "Medium":
                session.setAttribute("mediumCount", (int) session.getAttribute("mediumCount") + 1); break;
            case "Hard":
                session.setAttribute("hardCount",   (int) session.getAttribute("hardCount") + 1); break;
        }
    }

    private void clearExamSession(HttpSession session) {
        String[] keys = {"examId","attemptId","askedIds","totalScore","totalAnswered",
                         "totalCorrect","easyCount","mediumCount","hardCount",
                         "currentDifficulty","currentQuestion","questionNumber","examObj"};
        for (String k : keys) session.removeAttribute(k);
    }
}
