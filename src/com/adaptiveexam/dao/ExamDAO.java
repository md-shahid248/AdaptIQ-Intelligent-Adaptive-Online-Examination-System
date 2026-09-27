package com.adaptiveexam.dao;

import com.adaptiveexam.models.Exam;
import java.sql.*;
import java.util.*;

public class ExamDAO {

    public int createExam(Exam exam) {
        String sql = "INSERT INTO Exams (title, subject_id, created_by, duration_mins, total_questions, is_active) VALUES (?,?,?,?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, exam.getTitle().trim());
            ps.setInt(2, exam.getSubjectId());
            ps.setInt(3, exam.getCreatedBy());
            ps.setInt(4, exam.getDurationMins());
            ps.setInt(5, exam.getTotalQuestions());
            ps.setBoolean(6, exam.isActive());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) {
            System.err.println("ExamDAO.createExam error: " + e.getMessage());
        }
        return -1;
    }

    public void setDefaultMarks(int examId) {
        String sql = "INSERT INTO DifficultyMarks (exam_id, difficulty_level, marks) VALUES (?,?,?) ON DUPLICATE KEY UPDATE marks=VALUES(marks)";
        double[] defaults = {1.0, 2.0, 4.0};
        String[] levels = {"Easy", "Medium", "Hard"};
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < 3; i++) {
                ps.setInt(1, examId);
                ps.setString(2, levels[i]);
                ps.setDouble(3, defaults[i]);
                ps.addBatch();
            }
            ps.executeBatch();
        } catch (SQLException e) {
            System.err.println("ExamDAO.setDefaultMarks error: " + e.getMessage());
        }
    }

    public boolean updateMarks(int examId, double easyMarks, double mediumMarks, double hardMarks) {
        String sql = "INSERT INTO DifficultyMarks (exam_id, difficulty_level, marks) VALUES (?,?,?) ON DUPLICATE KEY UPDATE marks=?";
        String[] levels = {"Easy", "Medium", "Hard"};
        double[] marks = {easyMarks, mediumMarks, hardMarks};
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < 3; i++) {
                ps.setInt(1, examId);
                ps.setString(2, levels[i]);
                ps.setDouble(3, marks[i]);
                ps.setDouble(4, marks[i]);
                ps.addBatch();
            }
            ps.executeBatch();
            return true;
        } catch (SQLException e) {
            System.err.println("ExamDAO.updateMarks error: " + e.getMessage());
        }
        return false;
    }

    public Map<String, Double> getDifficultyMarks(int examId) {
        Map<String, Double> map = new HashMap<>();
        map.put("Easy", 1.0); map.put("Medium", 2.0); map.put("Hard", 4.0); // defaults
        String sql = "SELECT difficulty_level, marks FROM DifficultyMarks WHERE exam_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                map.put(rs.getString("difficulty_level"), rs.getDouble("marks"));
            }
        } catch (SQLException e) {
            System.err.println("ExamDAO.getDifficultyMarks error: " + e.getMessage());
        }
        return map;
    }

    public Exam getExamById(int id) {
        String sql = "SELECT e.*, s.name AS subject_name, u.name AS teacher_name " +
                     "FROM Exams e JOIN Subjects s ON s.id=e.subject_id JOIN Users u ON u.id=e.created_by " +
                     "WHERE e.id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapExam(rs);
        } catch (SQLException e) {
            System.err.println("ExamDAO.getExamById error: " + e.getMessage());
        }
        return null;
    }

    public List<Exam> getAllExams() {
        return getExamsQuery("SELECT e.*, s.name AS subject_name, u.name AS teacher_name " +
                             "FROM Exams e JOIN Subjects s ON s.id=e.subject_id JOIN Users u ON u.id=e.created_by " +
                             "ORDER BY e.created_at DESC", -1);
    }

    public List<Exam> getActiveExams() {
        return getExamsQuery("SELECT e.*, s.name AS subject_name, u.name AS teacher_name " +
                             "FROM Exams e JOIN Subjects s ON s.id=e.subject_id JOIN Users u ON u.id=e.created_by " +
                             "WHERE e.is_active=TRUE ORDER BY e.created_at DESC", -1);
    }

    public List<Exam> getExamsByTeacher(int teacherId) {
        return getExamsQuery("SELECT e.*, s.name AS subject_name, u.name AS teacher_name " +
                             "FROM Exams e JOIN Subjects s ON s.id=e.subject_id JOIN Users u ON u.id=e.created_by " +
                             "WHERE e.created_by=? ORDER BY e.created_at DESC", teacherId);
    }

    public boolean toggleActive(int examId) {
        String sql = "UPDATE Exams SET is_active = NOT is_active WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("ExamDAO.toggleActive error: " + e.getMessage());
        }
        return false;
    }

    public boolean deleteExam(int id) {
        String sql = "DELETE FROM Exams WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("ExamDAO.deleteExam error: " + e.getMessage());
        }
        return false;
    }

    public int getTotalExams() {
        String sql = "SELECT COUNT(*) FROM Exams";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("ExamDAO.getTotalExams error: " + e.getMessage());
        }
        return 0;
    }

    private List<Exam> getExamsQuery(String sql, int param) {
        List<Exam> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection()) {
            PreparedStatement ps;
            if (param >= 0) {
                ps = conn.prepareStatement(sql);
                ps.setInt(1, param);
            } else {
                ps = conn.prepareStatement(sql);
            }
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapExam(rs));
        } catch (SQLException e) {
            System.err.println("ExamDAO.getExamsQuery error: " + e.getMessage());
        }
        return list;
    }

    private Exam mapExam(ResultSet rs) throws SQLException {
        Exam e = new Exam();
        e.setId(rs.getInt("id"));
        e.setTitle(rs.getString("title"));
        e.setSubjectId(rs.getInt("subject_id"));
        e.setSubjectName(rs.getString("subject_name"));
        e.setCreatedBy(rs.getInt("created_by"));
        e.setCreatedByName(rs.getString("teacher_name"));
        e.setDurationMins(rs.getInt("duration_mins"));
        e.setTotalQuestions(rs.getInt("total_questions"));
        e.setActive(rs.getBoolean("is_active"));
        e.setCreatedAt(rs.getTimestamp("created_at"));
        return e;
    }
}
