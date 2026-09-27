<%@ page import="java.util.*, com.adaptiveexam.dao.*, com.adaptiveexam.models.*" %>
<%
    User __navUser = (User) session.getAttribute("user");
    if (__navUser == null) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        return;
    }
    String __role = __navUser.getRole();
    String __ctx  = request.getContextPath();
    String __name = __navUser.getName();
    String __initials = __name.length() >= 2 ? __name.substring(0,2).toUpperCase() : __name.toUpperCase();

    String __flash = (String) session.getAttribute("flash");
    if (__flash != null) session.removeAttribute("flash");
%>
<nav class="navbar">
  <a href="<%= __ctx %>/jsp/<%= __role.toLowerCase() %>/dashboard.jsp" class="navbar-brand">
    <div class="navbar-logo">AE</div>
    AdaptExam
  </a>

  <div class="navbar-nav">
    <% if ("Admin".equals(__role)) { %>
      <a href="<%= __ctx %>/jsp/admin/dashboard.jsp" class="nav-link">Dashboard</a>
      <a href="<%= __ctx %>/jsp/admin/manageUsers.jsp" class="nav-link">Users</a>
      <a href="<%= __ctx %>/jsp/admin/manageSubjects.jsp" class="nav-link">Subjects</a>
      <a href="<%= __ctx %>/jsp/teacher/manageExams.jsp" class="nav-link">Exams</a>
    <% } else if ("Teacher".equals(__role)) { %>
      <a href="<%= __ctx %>/jsp/teacher/dashboard.jsp" class="nav-link">Dashboard</a>
      <a href="<%= __ctx %>/jsp/teacher/manageExams.jsp" class="nav-link">My Exams</a>
      <a href="<%= __ctx %>/jsp/teacher/allAttempts.jsp" class="nav-link">Attempts</a>
      <a href="<%= __ctx %>/jsp/teacher/analytics.jsp" class="nav-link">Analytics</a>
    <% } else { %>
      <a href="<%= __ctx %>/jsp/student/dashboard.jsp" class="nav-link">Dashboard</a>
      <a href="<%= __ctx %>/jsp/student/history.jsp" class="nav-link">My History</a>
      <a href="<%= __ctx %>/jsp/student/analytics.jsp" class="nav-link">Analytics</a>
      <a href="<%= __ctx %>/jsp/student/leaderboard.jsp" class="nav-link">Leaderboard</a>
    <% } %>
  </div>

  <div class="navbar-user">
    <div class="user-badge">
      <div class="user-avatar"><%= __initials %></div>
      <span style="font-size:0.875rem;font-weight:600;color:white"><%= __name %></span>
      <span class="role-pill role-<%= __role.toLowerCase() %>"><%= __role %></span>
    </div>
    <form action="<%= __ctx %>/auth" method="POST" style="margin:0">
      <input type="hidden" name="action" value="logout">
      <button type="submit" class="btn btn-ghost btn-sm" style="color:#94a3b8;border-color:rgba(255,255,255,0.1)">Logout</button>
    </form>
  </div>
</nav>

<% if (__flash != null) { %>
  <div style="padding:0 28px;margin-top:-4px">
    <div class="alert alert-success" style="margin:12px 0"><i data-lucide="circle-check" style="width:16px;height:16px;flex-shrink:0"></i><%= __flash %></div>
  </div>
<% } %>
