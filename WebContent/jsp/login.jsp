<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Redirect if already logged in
    if (session.getAttribute("user") != null) {
        String role = (String) session.getAttribute("role");
        if ("Admin".equals(role))
            response.sendRedirect(request.getContextPath() + "/jsp/admin/dashboard.jsp");
        else if ("Teacher".equals(role))
            response.sendRedirect(request.getContextPath() + "/jsp/teacher/dashboard.jsp");
        else
            response.sendRedirect(request.getContextPath() + "/jsp/student/dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "AdaptExam — Login");
    request.setAttribute("useMono",   Boolean.TRUE);
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="common/head.jsp" %>
</head>
<body class="login-page">

  <div class="login-grid">

    <!-- Brand Panel -->
    <div class="login-brand">

      <div class="login-brand-logo">
        <div class="logo-mark">AE</div>
        <span style="font-size:1.4rem;font-weight:800;color:white;letter-spacing:-0.02em">AdaptExam</span>
      </div>

      <h1>
        Smarter Exams.<br>
        <span>Sharper Results.</span>
      </h1>

      <p>
        An adaptive examination platform that personalises every question
        based on your performance — delivering a fair, intelligent, and
        insightful experience.
      </p>

      <div class="login-features">
        <div class="login-feature">
          <div class="login-feature-icon"><i data-lucide="brain"></i></div>
          <span>AI-Adaptive Difficulty Engine — questions adjust in real time</span>
        </div>
        <div class="login-feature">
          <div class="login-feature-icon"><i data-lucide="chart-column"></i></div>
          <span>Deep Analytics — track accuracy, trends, and topic gaps</span>
        </div>
        <div class="login-feature">
          <div class="login-feature-icon"><i data-lucide="shield-check"></i></div>
          <span>Built-in Anti-Cheat — tab detection, copy block, auto-submit</span>
        </div>
        <div class="login-feature">
          <div class="login-feature-icon"><i data-lucide="trophy"></i></div>
          <span>Live Leaderboard — ranked results after every exam</span>
        </div>
      </div>
    </div>

    <!-- Login Form Panel -->
    <div class="login-card-wrap">

      <h2>Welcome back</h2>
      <p class="subtitle">Sign in to your account to continue</p>

      <% if (request.getAttribute("error") != null) { %>
        <div class="alert alert-error">
          <i data-lucide="triangle-alert"></i>
          <%= request.getAttribute("error") %>
        </div>
      <% } %>

      <form action="<%= request.getContextPath() %>/auth" method="POST" onsubmit="return validateLogin()">

        <input type="hidden" name="action" value="login">

        <div class="form-group">
          <label for="email">Email Address</label>
          <input type="email" id="email" name="email" placeholder="you@example.com" required autocomplete="email">
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" placeholder="Enter your password" required autocomplete="current-password">
        </div>

        <button type="submit" class="btn btn-amber btn-full btn-lg" style="margin-top:8px">
          Sign In
          <i data-lucide="arrow-right"></i>
        </button>

      </form>

      <!-- Test Credentials -->
     <!-- 
     <div style="margin-top:32px;padding:20px;background:#f8fafc;border-radius:10px;font-size:0.82rem;color:#64748b;border:1px solid #e2e8f0">

        <div style="font-weight:700;margin-bottom:10px;color:#334155">Test Credentials</div>

        <div style="display:grid;gap:6px">
          <div style="display:flex;align-items:center;gap:7px;">
            <i data-lucide="shield-user"></i>
            <span><strong>Admin:</strong> admin@test.com / Admin@123</span>
          </div>
          <div style="display:flex;align-items:center;gap:7px;">
            <i data-lucide="graduation-cap"></i>
            <span><strong>Teacher:</strong> teacher@test.com / Teacher@123</span>
          </div>
          <div style="display:flex;align-items:center;gap:7px;">
            <i data-lucide="user-round"></i>
            <span><strong>Student:</strong> student1@test.com / Student@123</span>
          </div>
        </div>

      </div> -->

    </div>

  </div>

  <script src="<%= request.getContextPath() %>/js/app.js"></script>
  <script>
    lucide.createIcons({ attrs: { 'stroke-width': 2 } });
  </script>
</body>
</html>
