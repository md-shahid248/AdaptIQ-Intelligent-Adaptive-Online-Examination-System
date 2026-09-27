package com.adaptiveexam.dao;

import com.adaptiveexam.models.Result;
import java.sql.*;
import java.util.*;

public class ResultDAO {

    public boolean saveResult(int attemptId, int studentId, int examId,
                              double totalScore, double maxPossible) {
        double pct = maxPossible > 0 ? (totalScore / maxPossible) * 100.0 : 0;
        String sql = "INSERT INTO Results (attempt_id, student_id, exam_id, total_score, max_possible_score, percentage) VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE total_score=?, max_possible_score=?, percentage=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attemptId);
            ps.setInt(2, studentId);
            ps.setInt(3, examId);
            ps.setDouble(4, totalScore);
            ps.setDouble(5, maxPossible);
            ps.setDouble(6, pct);
            ps.setDouble(7, totalScore);
            ps.setDouble(8, maxPossible);
            ps.setDouble(9, pct);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("ResultDAO.saveResult error: " + e.getMessage());
        }
        return false;
    }

    public Result getResultByAttempt(int attemptId) {
        String sql = "SELECT r.*, u.name AS student_name, e.title AS exam_title " +
                     "FROM Results r JOIN Users u ON u.id=r.student_id " +
                     "JOIN Exams e ON e.id=r.exam_id WHERE r.attempt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attemptId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapResult(rs);
        } catch (SQLException e) {
            System.err.println("ResultDAO.getResultByAttempt error: " + e.getMessage());
        }
        return null;
    }

    public List<Result> getLeaderboard(int examId) {
        List<Result> list = new ArrayList<>();
        String sql = "SELECT r.*, u.name AS student_name, e.title AS exam_title, " +
                     "RANK() OVER (PARTITION BY r.exam_id ORDER BY r.total_score DESC) AS rank_pos " +
                     "FROM Results r JOIN Users u ON u.id=r.student_id " +
                     "JOIN Exams e ON e.id=r.exam_id WHERE r.exam_id=? ORDER BY r.total_score DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Result result = mapResult(rs);
                result.setRankInExam(rs.getInt("rank_pos"));
                list.add(result);
            }
        } catch (SQLException e) {
            System.err.println("ResultDAO.getLeaderboard error: " + e.getMessage());
        }
        return list;
    }

    public List<Result> getResultsByStudent(int studentId) {
        List<Result> list = new ArrayList<>();
        String sql = "SELECT r.*, u.name AS student_name, e.title AS exam_title " +
                     "FROM Results r JOIN Users u ON u.id=r.student_id " +
                     "JOIN Exams e ON e.id=r.exam_id WHERE r.student_id=? ORDER BY r.id DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapResult(rs));
        } catch (SQLException e) {
            System.err.println("ResultDAO.getResultsByStudent error: " + e.getMessage());
        }
        return list;
    }

    public List<Map<String, Object>> getClassAnalytics(int teacherId) {
        List<Map<String, Object>> classData = new ArrayList<>();
        String sql = "SELECT e.title, COUNT(r.id) AS attempts, AVG(r.percentage) AS avg_pct, " +
                     "MAX(r.total_score) AS max_score, MIN(r.total_score) AS min_score " +
                     "FROM Results r JOIN Exams e ON e.id=r.exam_id " +
                     "WHERE e.created_by=? GROUP BY e.id, e.title ORDER BY e.id";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teacherId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("title",    rs.getString("title"));
                row.put("attempts", rs.getInt("attempts"));
                row.put("avgPct",   rs.getDouble("avg_pct"));
                row.put("maxScore", rs.getDouble("max_score"));
                row.put("minScore", rs.getDouble("min_score"));
                classData.add(row);
            }
        } catch (SQLException e) {
            System.err.println("ResultDAO.getClassAnalytics error: " + e.getMessage());
        }
        return classData;
    }

    private Result mapResult(ResultSet rs) throws SQLException {
        Result r = new Result();
        r.setId(rs.getInt("id"));
        r.setAttemptId(rs.getInt("attempt_id"));
        r.setStudentId(rs.getInt("student_id"));
        r.setExamId(rs.getInt("exam_id"));
        r.setTotalScore(rs.getDouble("total_score"));
        r.setMaxPossibleScore(rs.getDouble("max_possible_score"));
        r.setPercentage(rs.getDouble("percentage"));
        try { r.setStudentName(rs.getString("student_name")); } catch (SQLException ignored) {}
        try { r.setExamTitle(rs.getString("exam_title"));   } catch (SQLException ignored) {}
        return r;
    }
}
