package com.adaptiveexam.dao;

import com.adaptiveexam.models.ExamAttempt;
import com.adaptiveexam.models.StudentResponse;
import java.sql.*;
import java.util.*;

public class AttemptDAO {

    /** Creates an in-progress attempt and returns the generated attempt_id */
    public int createAttempt(int studentId, int examId) {
        String sql = "INSERT INTO ExamAttempts (student_id, exam_id, status) VALUES (?,?,'In-Progress')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, studentId);
            ps.setInt(2, examId);
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) {
            System.err.println("AttemptDAO.createAttempt error: " + e.getMessage());
        }
        return -1;
    }

    /** Finalizes the attempt with score, accuracy, summary, and status */
    public boolean finalizeAttempt(int attemptId, double score, double accuracy,
                                   String difficultySummary, String status) {
        String sql = "UPDATE ExamAttempts SET score=?, accuracy=?, difficulty_summary=?, status=? WHERE attempt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, score);
            ps.setDouble(2, accuracy);
            ps.setString(3, difficultySummary);
            ps.setString(4, status);
            ps.setInt(5, attemptId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("AttemptDAO.finalizeAttempt error: " + e.getMessage());
        }
        return false;
    }

    /** Saves a single student response for a question */
    public void saveResponse(int attemptId, int questionId, char selectedAnswer,
                             boolean isCorrect, double marksAwarded) {
        String sql = "INSERT INTO StudentResponses (attempt_id, question_id, selected_answer, is_correct, marks_awarded) VALUES (?,?,?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attemptId);
            ps.setInt(2, questionId);
            ps.setString(3, String.valueOf(selectedAnswer));
            ps.setBoolean(4, isCorrect);
            ps.setDouble(5, marksAwarded);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.err.println("AttemptDAO.saveResponse error: " + e.getMessage());
        }
    }

    public List<ExamAttempt> getAttemptsByStudent(int studentId) {
        List<ExamAttempt> list = new ArrayList<>();
        String sql = "SELECT ea.*, e.title AS exam_title FROM ExamAttempts ea " +
                     "JOIN Exams e ON e.id=ea.exam_id " +
                     "WHERE ea.student_id=? AND ea.status != 'In-Progress' ORDER BY ea.date_time DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, studentId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapAttempt(rs));
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getAttemptsByStudent error: " + e.getMessage());
        }
        return list;
    }

    public List<ExamAttempt> getAttemptsByExam(int examId) {
        List<ExamAttempt> list = new ArrayList<>();
        String sql = "SELECT ea.*, u.name AS student_name, e.title AS exam_title " +
                     "FROM ExamAttempts ea JOIN Users u ON u.id=ea.student_id " +
                     "JOIN Exams e ON e.id=ea.exam_id " +
                     "WHERE ea.exam_id=? AND ea.status != 'In-Progress' ORDER BY ea.date_time DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapAttempt(rs));
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getAttemptsByExam error: " + e.getMessage());
        }
        return list;
    }

    public List<ExamAttempt> getAllAttemptsForTeacher(int teacherId) {
        List<ExamAttempt> list = new ArrayList<>();
        String sql = "SELECT ea.*, u.name AS student_name, e.title AS exam_title " +
                     "FROM ExamAttempts ea JOIN Users u ON u.id=ea.student_id " +
                     "JOIN Exams e ON e.id=ea.exam_id " +
                     "WHERE e.created_by=? AND ea.status != 'In-Progress' ORDER BY ea.date_time DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teacherId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapAttempt(rs));
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getAllAttemptsForTeacher error: " + e.getMessage());
        }
        return list;
    }

    public ExamAttempt getAttemptById(int attemptId) {
        String sql = "SELECT ea.*, u.name AS student_name, e.title AS exam_title " +
                     "FROM ExamAttempts ea JOIN Users u ON u.id=ea.student_id " +
                     "JOIN Exams e ON e.id=ea.exam_id WHERE ea.attempt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attemptId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapAttempt(rs);
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getAttemptById error: " + e.getMessage());
        }
        return null;
    }

    public List<StudentResponse> getResponsesByAttempt(int attemptId) {
        List<StudentResponse> list = new ArrayList<>();
        String sql = "SELECT sr.*, q.question_text, q.difficulty, q.topic, q.correct_answer " +
                     "FROM StudentResponses sr JOIN Questions q ON q.id=sr.question_id " +
                     "WHERE sr.attempt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, attemptId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                StudentResponse r = new StudentResponse();
                r.setId(rs.getInt("id"));
                r.setAttemptId(attemptId);
                r.setQuestionId(rs.getInt("question_id"));
                r.setQuestionText(rs.getString("question_text"));
                r.setDifficulty(rs.getString("difficulty"));
                r.setTopic(rs.getString("topic"));
                String sel = rs.getString("selected_answer");
                r.setSelectedAnswer(sel != null && !sel.isEmpty() ? sel.charAt(0) : '-');
                r.setCorrect(rs.getBoolean("is_correct"));
                r.setMarksAwarded(rs.getDouble("marks_awarded"));
                String ca = rs.getString("correct_answer");
                r.setCorrectAnswer(ca != null && !ca.isEmpty() ? ca.charAt(0) : 'A');
                list.add(r);
            }
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getResponsesByAttempt error: " + e.getMessage());
        }
        return list;
    }

    public int getTotalAttempts() {
        String sql = "SELECT COUNT(*) FROM ExamAttempts WHERE status != 'In-Progress'";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("AttemptDAO.getTotalAttempts error: " + e.getMessage());
        }
        return 0;
    }

    private ExamAttempt mapAttempt(ResultSet rs) throws SQLException {
        ExamAttempt a = new ExamAttempt();
        a.setAttemptId(rs.getInt("attempt_id"));
        a.setStudentId(rs.getInt("student_id"));
        a.setExamId(rs.getInt("exam_id"));
        a.setScore(rs.getDouble("score"));
        a.setAccuracy(rs.getDouble("accuracy"));
        a.setDateTime(rs.getTimestamp("date_time"));
        a.setDifficultySummary(rs.getString("difficulty_summary"));
        a.setStatus(rs.getString("status"));
        try { a.setStudentName(rs.getString("student_name")); } catch (SQLException ignored) {}
        try { a.setExamTitle(rs.getString("exam_title")); } catch (SQLException ignored) {}
        return a;
    }
}
