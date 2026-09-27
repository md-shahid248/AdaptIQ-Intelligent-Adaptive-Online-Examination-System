package com.adaptiveexam.dao;

import com.adaptiveexam.models.Question;
import java.sql.*;
import java.util.*;

public class QuestionDAO {

    public boolean addQuestion(Question q) {
        String sql = "INSERT INTO Questions (exam_id, question_text, option_a, option_b, option_c, option_d, correct_answer, difficulty, topic, created_by) VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, q.getExamId());
            ps.setString(2, q.getQuestionText().trim());
            ps.setString(3, q.getOptionA().trim());
            ps.setString(4, q.getOptionB().trim());
            ps.setString(5, q.getOptionC().trim());
            ps.setString(6, q.getOptionD().trim());
            ps.setString(7, String.valueOf(q.getCorrectAnswer()));
            ps.setString(8, q.getDifficulty());
            ps.setString(9, q.getTopic() == null ? "General" : q.getTopic().trim());
            ps.setInt(10, q.getCreatedBy());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("QuestionDAO.addQuestion error: " + e.getMessage());
        }
        return false;
    }

    public boolean deleteQuestion(int id) {
        String sql = "DELETE FROM Questions WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("QuestionDAO.deleteQuestion error: " + e.getMessage());
        }
        return false;
    }

    public Question getQuestionById(int id) {
        String sql = "SELECT * FROM Questions WHERE id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapQuestion(rs);
        } catch (SQLException e) {
            System.err.println("QuestionDAO.getQuestionById error: " + e.getMessage());
        }
        return null;
    }

    public List<Question> getQuestionsByExam(int examId) {
        List<Question> list = new ArrayList<>();
        String sql = "SELECT * FROM Questions WHERE exam_id=? ORDER BY difficulty, topic";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapQuestion(rs));
        } catch (SQLException e) {
            System.err.println("QuestionDAO.getQuestionsByExam error: " + e.getMessage());
        }
        return list;
    }

    /**
     * Core adaptive fetch: gets one random question of given difficulty,
     * excluding already-asked question IDs.
     */
    public Question getAdaptiveQuestion(int examId, String difficulty, List<Integer> excludeIds) {
        StringBuilder excludeStr = new StringBuilder("0");
        for (int id : excludeIds) excludeStr.append(",").append(id);

        String sql = "SELECT * FROM Questions WHERE exam_id=? AND difficulty=? AND id NOT IN (" + excludeStr + ") ORDER BY RAND() LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ps.setString(2, difficulty);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapQuestion(rs);
        } catch (SQLException e) {
            System.err.println("QuestionDAO.getAdaptiveQuestion error: " + e.getMessage());
        }
        return null;
    }

    /** Returns count of questions per difficulty for an exam */
    public Map<String, Integer> getQuestionCountByDifficulty(int examId) {
        Map<String, Integer> map = new HashMap<>();
        map.put("Easy", 0); map.put("Medium", 0); map.put("Hard", 0);
        String sql = "SELECT difficulty, COUNT(*) AS cnt FROM Questions WHERE exam_id=? GROUP BY difficulty";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, examId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) map.put(rs.getString("difficulty"), rs.getInt("cnt"));
        } catch (SQLException e) {
            System.err.println("QuestionDAO.getQuestionCountByDifficulty error: " + e.getMessage());
        }
        return map;
    }

    public int getTotalQuestions() {
        String sql = "SELECT COUNT(*) FROM Questions";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("QuestionDAO.getTotalQuestions error: " + e.getMessage());
        }
        return 0;
    }

    private Question mapQuestion(ResultSet rs) throws SQLException {
        Question q = new Question();
        q.setId(rs.getInt("id"));
        q.setExamId(rs.getInt("exam_id"));
        q.setQuestionText(rs.getString("question_text"));
        q.setOptionA(rs.getString("option_a"));
        q.setOptionB(rs.getString("option_b"));
        q.setOptionC(rs.getString("option_c"));
        q.setOptionD(rs.getString("option_d"));
        String ca = rs.getString("correct_answer");
        q.setCorrectAnswer(ca != null && !ca.isEmpty() ? ca.charAt(0) : 'A');
        q.setDifficulty(rs.getString("difficulty"));
        q.setTopic(rs.getString("topic"));
        q.setCreatedBy(rs.getInt("created_by"));
        return q;
    }
}
