package com.adaptiveexam.dao;

import com.adaptiveexam.models.Subject;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SubjectDAO {

    public List<Subject> getAllSubjects() {
        List<Subject> list = new ArrayList<>();
        String sql = "SELECT * FROM Subjects ORDER BY name";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) list.add(mapSubject(rs));
        } catch (SQLException e) {
            System.err.println("SubjectDAO.getAllSubjects error: " + e.getMessage());
        }
        return list;
    }

    public boolean addSubject(Subject subject) {
        String sql = "INSERT INTO Subjects (name, description) VALUES (?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, subject.getName().trim());
            ps.setString(2, subject.getDescription());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("SubjectDAO.addSubject error: " + e.getMessage());
        }
        return false;
    }

    public boolean deleteSubject(int id) {
        String sql = "DELETE FROM Subjects WHERE id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("SubjectDAO.deleteSubject error: " + e.getMessage());
        }
        return false;
    }

    public int getTotalSubjects() {
        String sql = "SELECT COUNT(*) FROM Subjects";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("SubjectDAO.getTotalSubjects error: " + e.getMessage());
        }
        return 0;
    }

    private Subject mapSubject(ResultSet rs) throws SQLException {
        return new Subject(rs.getInt("id"), rs.getString("name"), rs.getString("description"));
    }
}
