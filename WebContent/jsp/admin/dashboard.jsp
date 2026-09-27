<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.adaptiveexam.dao.*, com.adaptiveexam.models.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Admin".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        return;
    }

    UserDAO    uDao = new UserDAO();
    ExamDAO    eDao = new ExamDAO();
    SubjectDAO sDao = new SubjectDAO();
    AttemptDAO aDao = new AttemptDAO();

    int totalStudents = uDao.getTotalUsersByRole("Student");
    int totalTeachers = uDao.getTotalUsersByRole("Teacher");
    int totalExams    = eDao.getTotalExams();
    int totalSubjects = sDao.getTotalSubjects();
    int totalAttempts = aDao.getTotalAttempts();

    List<User> allUsers = uDao.getAllUsers();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Admin Dashboard — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">

  <div class="page-header">
    <div>
      <h1>Admin Dashboard</h1>
      <p>System overview and management controls</p>
    </div>
  </div>

  <!-- Statistics -->
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="graduation-cap"></i></div>
      <div>
        <div class="stat-label">Students</div>
        <div class="stat-value"><%= totalStudents %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-sky"><i data-lucide="user-round-check"></i></div>
      <div>
        <div class="stat-label">Teachers</div>
        <div class="stat-value"><%= totalTeachers %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-navy"><i data-lucide="clipboard-list"></i></div>
      <div>
        <div class="stat-label">Exams</div>
        <div class="stat-value"><%= totalExams %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-green"><i data-lucide="book-open"></i></div>
      <div>
        <div class="stat-label">Subjects</div>
        <div class="stat-value"><%= totalSubjects %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-rose"><i data-lucide="chart-column"></i></div>
      <div>
        <div class="stat-label">Exam Attempts</div>
        <div class="stat-value"><%= totalAttempts %></div>
      </div>
    </div>
  </div>

  <!-- Dashboard Content -->
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:8px">

    <!-- Quick Actions -->
    <div class="card">
      <div class="card-header"><h3>Quick Actions</h3></div>
      <div class="card-body" style="display:flex;flex-direction:column;gap:12px">
        <a href="<%= request.getContextPath() %>/jsp/admin/manageUsers.jsp" class="btn btn-primary btn-full">
          <i data-lucide="users"></i>
          <span>Manage Users</span>
        </a>
        <a href="<%= request.getContextPath() %>/jsp/admin/manageSubjects.jsp" class="btn btn-primary btn-full">
          <i data-lucide="book-open"></i>
          <span>Manage Subjects</span>
        </a>
        <a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp" class="btn btn-amber btn-full">
          <i data-lucide="clipboard-list"></i>
          <span>Manage Exams</span>
        </a>
        <a href="<%= request.getContextPath() %>/jsp/teacher/allAttempts.jsp" class="btn btn-ghost btn-full">
          <i data-lucide="bar-chart-3"></i>
          <span>View All Attempts</span>
        </a>
      </div>
    </div>

    <!-- Recent Users -->
    <div class="card">
      <div class="card-header"><h3>Recent Users</h3></div>
      <div class="card-body" style="padding:0">
        <table>
          <thead>
            <tr><th>Name</th><th>Role</th><th>Email</th></tr>
          </thead>
          <tbody>
            <% for (User u : allUsers.subList(0, Math.min(5, allUsers.size()))) { %>
            <tr>
              <td><strong><%= u.getName() %></strong></td>
              <td><span class="badge badge-navy"><%= u.getRole() %></span></td>
              <td style="color:#64748b;font-size:0.85rem"><%= u.getEmail() %></td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>

  </div>
</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
  lucide.createIcons({ attrs: { 'stroke-width': 2 } });
</script>
</body>
</html>
