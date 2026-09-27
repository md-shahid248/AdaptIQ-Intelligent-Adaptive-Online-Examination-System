package com.adaptiveexam.servlets;

import com.adaptiveexam.dao.*;
import com.adaptiveexam.models.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/teacher")
public class TeacherServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (!isTeacherOrAdmin(session)) {
            res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
            return;
        }

        User user = (User) session.getAttribute("user");
        String action = req.getParameter("action");
        String ctx    = req.getContextPath();

        switch (action == null ? "" : action) {

            case "createExam": {
                Exam e = new Exam();
                e.setTitle(req.getParameter("title"));
                e.setSubjectId(Integer.parseInt(req.getParameter("subjectId")));
                e.setCreatedBy(user.getId());
                e.setDurationMins(Integer.parseInt(req.getParameter("durationMins")));
                e.setTotalQuestions(Integer.parseInt(req.getParameter("totalQuestions")));
                e.setActive(true);

                ExamDAO dao = new ExamDAO();
                int examId = dao.createExam(e);

                if (examId > 0) {
                    // Parse custom marks or use defaults
                    double easyM   = parseDouble(req.getParameter("easyMarks"),   1.0);
                    double mediumM = parseDouble(req.getParameter("mediumMarks"), 2.0);
                    double hardM   = parseDouble(req.getParameter("hardMarks"),   4.0);
                    dao.updateMarks(examId, easyM, mediumM, hardM);
                    session.setAttribute("flash", "Exam created successfully! ID: " + examId);
                } else {
                    session.setAttribute("flash", "Failed to create exam.");
                }
                res.sendRedirect(ctx + "/jsp/teacher/manageExams.jsp");
                break;
            }

            case "toggleExam": {
                int examId = Integer.parseInt(req.getParameter("examId"));
                new ExamDAO().toggleActive(examId);
                session.setAttribute("flash", "Exam status updated.");
                res.sendRedirect(ctx + "/jsp/teacher/manageExams.jsp");
                break;
            }

            case "deleteExam": {
                int examId = Integer.parseInt(req.getParameter("examId"));
                new ExamDAO().deleteExam(examId);
                session.setAttribute("flash", "Exam deleted.");
                res.sendRedirect(ctx + "/jsp/teacher/manageExams.jsp");
                break;
            }

            case "updateMarks": {
                int examId     = Integer.parseInt(req.getParameter("examId"));
                double easyM   = parseDouble(req.getParameter("easyMarks"),   1.0);
                double mediumM = parseDouble(req.getParameter("mediumMarks"), 2.0);
                double hardM   = parseDouble(req.getParameter("hardMarks"),   4.0);
                new ExamDAO().updateMarks(examId, easyM, mediumM, hardM);
                session.setAttribute("flash", "Marks distribution updated.");
                res.sendRedirect(ctx + "/jsp/teacher/manageExams.jsp");
                break;
            }

            case "addQuestion": {
                Question q = new Question();
                q.setExamId(Integer.parseInt(req.getParameter("examId")));
                q.setQuestionText(req.getParameter("questionText"));
                q.setOptionA(req.getParameter("optionA"));
                q.setOptionB(req.getParameter("optionB"));
                q.setOptionC(req.getParameter("optionC"));
                q.setOptionD(req.getParameter("optionD"));
                String ca = req.getParameter("correctAnswer");
                q.setCorrectAnswer(ca != null && !ca.isEmpty() ? ca.charAt(0) : 'A');
                q.setDifficulty(req.getParameter("difficulty"));
                q.setTopic(req.getParameter("topic"));
                q.setCreatedBy(user.getId());

                boolean ok = new QuestionDAO().addQuestion(q);
                session.setAttribute("flash", ok ? "Question added successfully." : "Failed to add question.");
                res.sendRedirect(ctx + "/jsp/teacher/questionBank.jsp?examId=" + q.getExamId());
                break;
            }

            case "deleteQuestion": {
                int qId    = Integer.parseInt(req.getParameter("qId"));
                int examId = Integer.parseInt(req.getParameter("examId"));
                new QuestionDAO().deleteQuestion(qId);
                session.setAttribute("flash", "Question deleted.");
                res.sendRedirect(ctx + "/jsp/teacher/questionBank.jsp?examId=" + examId);
                break;
            }

            default:
                res.sendRedirect(ctx + "/jsp/teacher/dashboard.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.sendRedirect(req.getContextPath() + "/jsp/teacher/dashboard.jsp");
    }

    private boolean isTeacherOrAdmin(HttpSession session) {
        if (session == null) return false;
        User u = (User) session.getAttribute("user");
        return u != null && ("Teacher".equals(u.getRole()) || "Admin".equals(u.getRole()));
    }

    private double parseDouble(String val, double defaultVal) {
        try { return Double.parseDouble(val); }
        catch (Exception e) { return defaultVal; }
    }
}
