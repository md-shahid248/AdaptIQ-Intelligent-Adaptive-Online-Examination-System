package com.adaptiveexam.servlets;

import com.adaptiveexam.dao.*;
import com.adaptiveexam.models.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;

@WebServlet("/analytics")
public class AnalyticsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            res.setStatus(401);
            return;
        }

        User user = (User) session.getAttribute("user");
        String type = req.getParameter("type");

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        if ("student".equals(type)) {
            out.print(buildStudentAnalytics(user.getId()));
        } else if ("teacher".equals(type)) {
            if (!"Teacher".equals(user.getRole()) && !"Admin".equals(user.getRole())) {
                res.setStatus(403); return;
            }
            int examId = 0;
            try { examId = Integer.parseInt(req.getParameter("examId")); } catch (Exception ignored) {}
            out.print(buildTeacherAnalytics(user.getId(), examId));
        } else if ("questionPerf".equals(type)) {
            int examId = 0;
            try { examId = Integer.parseInt(req.getParameter("examId")); } catch (Exception ignored) {}
            out.print(buildQuestionPerformance(examId));
        }

        out.flush();
    }

    // ── Student analytics: score trend + difficulty accuracy ──
    private String buildStudentAnalytics(int studentId) {
        List<Result> results = new ResultDAO().getResultsByStudent(studentId);
        List<ExamAttempt> attempts = new AttemptDAO().getAttemptsByStudent(studentId);

        StringBuilder sb = new StringBuilder("{");

        // Score trend (last 8)
        int limit = Math.min(results.size(), 8);
        sb.append("\"examLabels\":[");
        for (int i = limit - 1; i >= 0; i--) {
            sb.append("\"").append(escapeJson(results.get(i).getExamTitle())).append("\"");
            if (i > 0) sb.append(",");
        }
        sb.append("],\"scorePercents\":[");
        for (int i = limit - 1; i >= 0; i--) {
            sb.append(String.format("%.1f", results.get(i).getPercentage()));
            if (i > 0) sb.append(",");
        }
        sb.append("],");

        // Difficulty accuracy from attempts (parse difficulty_summary)
        int[] correct = {0, 0, 0}; // easy, medium, hard
        int[] total   = {0, 0, 0};
        for (ExamAttempt a : attempts) {
            if (a.getDifficultySummary() == null) continue;
            // Parse "Easy:4,Medium:8,Hard:3"
            for (String part : a.getDifficultySummary().split(",")) {
                String[] kv = part.split(":");
                if (kv.length == 2) {
                    int cnt = 0;
                    try { cnt = Integer.parseInt(kv[1].trim()); } catch (Exception ignored) {}
                    switch (kv[0].trim()) {
                        case "Easy":   total[0] += cnt; break;
                        case "Medium": total[1] += cnt; break;
                        case "Hard":   total[2] += cnt; break;
                    }
                }
            }
        }

        // Get per-difficulty correct counts from StudentResponses
        AttemptDAO dao = new AttemptDAO();
        for (ExamAttempt a : attempts) {
            List<StudentResponse> responses = dao.getResponsesByAttempt(a.getAttemptId());
            for (StudentResponse sr : responses) {
                if (sr.isCorrect()) {
                    switch (sr.getDifficulty()) {
                        case "Easy":   correct[0]++; break;
                        case "Medium": correct[1]++; break;
                        case "Hard":   correct[2]++; break;
                    }
                }
            }
        }

        double easyAcc   = total[0] > 0 ? (correct[0] * 100.0 / total[0]) : 0;
        double mediumAcc = total[1] > 0 ? (correct[1] * 100.0 / total[1]) : 0;
        double hardAcc   = total[2] > 0 ? (correct[2] * 100.0 / total[2]) : 0;

        sb.append(String.format("\"easyAcc\":%.1f,\"mediumAcc\":%.1f,\"hardAcc\":%.1f,", easyAcc, mediumAcc, hardAcc));

        // Totals for doughnut
        int totalCorrect   = correct[0] + correct[1] + correct[2];
        int totalAttempted = total[0] + total[1] + total[2];
        int totalIncorrect = totalAttempted - totalCorrect;

        sb.append("\"correct\":").append(totalCorrect).append(",");
        sb.append("\"incorrect\":").append(totalIncorrect).append(",");
        sb.append("\"skipped\":0,");
        sb.append("\"totalExams\":").append(results.size());
        sb.append("}");
        return sb.toString();
    }

    // ── Teacher analytics: class performance per exam ──
    private String buildTeacherAnalytics(int teacherId, int examId) {
        List<Map<String, Object>> analytics = new ResultDAO().getClassAnalytics(teacherId);

        StringBuilder sb = new StringBuilder("{\"exams\":[");
        for (int i = 0; i < analytics.size(); i++) {
            Map<String, Object> row = analytics.get(i);
            sb.append("{");
            sb.append("\"title\":\"").append(escapeJson((String) row.get("title"))).append("\",");
            sb.append("\"attempts\":").append(row.get("attempts")).append(",");
            sb.append("\"avgPct\":").append(String.format("%.1f", (double) row.get("avgPct"))).append(",");
            sb.append("\"maxScore\":").append(String.format("%.1f", (double) row.get("maxScore"))).append(",");
            sb.append("\"minScore\":").append(String.format("%.1f", (double) row.get("minScore")));
            sb.append("}");
            if (i < analytics.size() - 1) sb.append(",");
        }
        sb.append("]}");
        return sb.toString();
    }

    // ── Question performance: success rate per question ──
    private String buildQuestionPerformance(int examId) {
        if (examId <= 0) return "{\"questions\":[]}";

        String sql = "SELECT q.question_text, q.difficulty, q.topic, " +
                     "COUNT(sr.id) AS total, " +
                     "SUM(CASE WHEN sr.is_correct=1 THEN 1 ELSE 0 END) AS correct_cnt " +
                     "FROM Questions q LEFT JOIN StudentResponses sr ON sr.question_id=q.id " +
                     "WHERE q.exam_id=? GROUP BY q.id,q.question_text,q.difficulty,q.topic " +
                     "ORDER BY correct_cnt/NULLIF(total,0) ASC";

        StringBuilder sb = new StringBuilder("{\"questions\":[");
        try (java.sql.Connection conn = DBConnection.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            java.sql.ResultSet rs = ps.executeQuery();
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                first = false;
                int tot  = rs.getInt("total");
                int corr = rs.getInt("correct_cnt");
                double rate = tot > 0 ? (corr * 100.0 / tot) : 0;
                sb.append("{");
                sb.append("\"text\":\"").append(escapeJson(rs.getString("question_text"))).append("\",");
                sb.append("\"difficulty\":\"").append(rs.getString("difficulty")).append("\",");
                sb.append("\"topic\":\"").append(escapeJson(rs.getString("topic"))).append("\",");
                sb.append("\"total\":").append(tot).append(",");
                sb.append("\"correct\":").append(corr).append(",");
                sb.append("\"rate\":").append(String.format("%.1f", rate));
                sb.append("}");
            }
        } catch (Exception e) {
            System.err.println("AnalyticsServlet.buildQuestionPerformance error: " + e.getMessage());
        }
        sb.append("]}");
        return sb.toString();
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}
