package com.adaptiveexam.servlets;

import com.adaptiveexam.dao.*;
import com.adaptiveexam.models.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (!isAdmin(session)) {
            res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        String ctx    = req.getContextPath();

        switch (action == null ? "" : action) {

            case "addUser": {
                User u = new User();
                u.setName(req.getParameter("name"));
                u.setEmail(req.getParameter("email"));
                u.setPassword(req.getParameter("password"));
                u.setRole(req.getParameter("role"));
                boolean ok = new UserDAO().addUser(u);
                req.getSession().setAttribute("flash", ok ? "User added successfully." : "Failed to add user. Email may already exist.");
                res.sendRedirect(ctx + "/jsp/admin/manageUsers.jsp");
                break;
            }

            case "deleteUser": {
                int id = Integer.parseInt(req.getParameter("id"));
                int myId = (int) session.getAttribute("userId");
                if (id == myId) {
                    req.getSession().setAttribute("flash", "Cannot delete your own account.");
                } else {
                    new UserDAO().deleteUser(id);
                    req.getSession().setAttribute("flash", "User deleted.");
                }
                res.sendRedirect(ctx + "/jsp/admin/manageUsers.jsp");
                break;
            }

            case "addSubject": {
                Subject s = new Subject();
                s.setName(req.getParameter("name"));
                s.setDescription(req.getParameter("description"));
                boolean ok = new SubjectDAO().addSubject(s);
                req.getSession().setAttribute("flash", ok ? "Subject added." : "Failed. Subject may already exist.");
                res.sendRedirect(ctx + "/jsp/admin/manageSubjects.jsp");
                break;
            }

            case "deleteSubject": {
                int id = Integer.parseInt(req.getParameter("id"));
                new SubjectDAO().deleteSubject(id);
                req.getSession().setAttribute("flash", "Subject deleted.");
                res.sendRedirect(ctx + "/jsp/admin/manageSubjects.jsp");
                break;
            }

            default:
                res.sendRedirect(ctx + "/jsp/admin/dashboard.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.sendRedirect(req.getContextPath() + "/jsp/admin/dashboard.jsp");
    }

    private boolean isAdmin(HttpSession session) {
        if (session == null) return false;
        User u = (User) session.getAttribute("user");
        return u != null && "Admin".equals(u.getRole());
    }
}
