package com.adaptiveexam.servlets;

import com.adaptiveexam.dao.UserDAO;
import com.adaptiveexam.models.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/auth")
public class AuthServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        System.out.println("========== AuthServlet ==========");

        try {

            String action = req.getParameter("action");

            if ("logout".equalsIgnoreCase(action)) {
                doLogout(req, res);
                return;
            }

            // Login
            String email = req.getParameter("email");
            String password = req.getParameter("password");

            System.out.println("Email : " + email);

            if (email == null || email.trim().isEmpty()
                    || password == null || password.trim().isEmpty()) {

                req.setAttribute("error", "Email and password are required.");
                req.getRequestDispatcher("/jsp/login.jsp").forward(req, res);
                return;
            }

            UserDAO dao = new UserDAO();

            User user = dao.authenticate(email.trim().toLowerCase(), password);

            System.out.println("Authenticated User : " + user);

            if (user == null) {

                System.out.println("Login Failed");

                req.setAttribute("error", "Invalid email or password.");
                req.getRequestDispatcher("/jsp/login.jsp").forward(req, res);
                return;
            }

            System.out.println("User ID : " + user.getId());
            System.out.println("User Name : " + user.getName());
            System.out.println("Role : " + user.getRole());

            // Create Session
            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);
            session.setAttribute("userId", user.getId());
            session.setAttribute("userName", user.getName());
            session.setAttribute("role", user.getRole());
            session.setMaxInactiveInterval(1800);

            String ctx = req.getContextPath();

            String role = user.getRole();

            if ("Admin".equalsIgnoreCase(role)) {
                System.out.println("Redirecting to Admin Dashboard...");
                res.sendRedirect(ctx + "/jsp/admin/dashboard.jsp");

            } else if ("Teacher".equalsIgnoreCase(role)) {
                System.out.println("Redirecting to Teacher Dashboard...");
                res.sendRedirect(ctx + "/jsp/teacher/dashboard.jsp");

            } else if ("Student".equalsIgnoreCase(role)) {
                System.out.println("Redirecting to Student Dashboard...");
                res.sendRedirect(ctx + "/jsp/student/dashboard.jsp");

            } else {

                System.out.println("Unknown Role : " + role);

                session.invalidate();

                req.setAttribute("error", "Unknown user role.");
                req.getRequestDispatcher("/jsp/login.jsp").forward(req, res);
            }

        } catch (Exception e) {

            System.out.println("========== LOGIN ERROR ==========");
            e.printStackTrace();

            req.setAttribute("error", "Internal server error.");

            req.getRequestDispatcher("/jsp/login.jsp").forward(req, res);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        System.out.println("GET /auth");

        res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
    }

    private void doLogout(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        HttpSession session = req.getSession(false);

        if (session != null) {
            session.invalidate();
        }

        System.out.println("User Logged Out");

        res.sendRedirect(req.getContextPath() + "/jsp/login.jsp");
    }
}