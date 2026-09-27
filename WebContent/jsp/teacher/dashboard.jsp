<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null ||
        (!"Teacher".equals(currentUser.getRole()) &&
         !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        return;
    }

    ExamDAO     eDao = new ExamDAO();
    AttemptDAO  aDao = new AttemptDAO();
    QuestionDAO qDao = new QuestionDAO();

    List<Exam> myExams = eDao.getExamsByTeacher(currentUser.getId());
    List<ExamAttempt> recentAttempts = aDao.getAllAttemptsForTeacher(currentUser.getId());

    int totalQ = qDao.getTotalQuestions();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Teacher Dashboard — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">

  <div class="page-header">
    <div>
      <h1>Teacher Dashboard</h1>
      <p>Welcome back, <%= currentUser.getName() %>!</p>
    </div>
    <a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp" class="btn btn-amber">
      <i data-lucide="plus"></i>
      <span>Create Exam</span>
    </a>
  </div>

  <!-- Statistics -->
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-icon stat-icon-navy"><i data-lucide="clipboard-list"></i></div>
      <div>
        <div class="stat-label">My Exams</div>
        <div class="stat-value"><%= myExams.size() %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="chart-column"></i></div>
      <div>
        <div class="stat-label">Total Attempts</div>
        <div class="stat-value"><%= recentAttempts.size() %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-green"><i data-lucide="circle-help"></i></div>
      <div>
        <div class="stat-label">Total Questions</div>
        <div class="stat-value"><%= totalQ %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-sky"><i data-lucide="circle-check"></i></div>
      <div>
        <div class="stat-label">Active Exams</div>
        <div class="stat-value"><%= myExams.stream().filter(Exam::isActive).count() %></div>
      </div>
    </div>
  </div>

  <!-- Dashboard Tables -->
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px">

    <!-- My Exams -->
    <div class="card">
      <div class="card-header">
        <h3>My Exams</h3>
        <a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp" class="btn btn-ghost btn-sm">View All</a>
      </div>
      <div class="table-wrap" style="border:none">
        <table>
          <thead>
            <tr><th>Title</th><th>Subject</th><th>Status</th><th>Actions</th></tr>
          </thead>
          <tbody>
            <% if (myExams.isEmpty()) { %>
            <tr><td colspan="4">
              <div class="empty-state" style="padding:30px">
                <div class="empty-state-icon"><i data-lucide="clipboard-list"></i></div>
                <h3>No exams yet</h3>
                <p><a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp">Create your first exam</a></p>
              </div>
            </td></tr>
            <% } %>

            <% for (Exam ex : myExams.subList(0, Math.min(5, myExams.size()))) { %>
            <tr>
              <td>
                <strong><%= ex.getTitle() %></strong><br>
                <span style="font-size:0.78rem;color:#94a3b8"><%= ex.getDurationMins() %>min · <%= ex.getTotalQuestions() %>Q</span>
              </td>
              <td style="font-size:0.875rem;color:#64748b"><%= ex.getSubjectName() %></td>
              <td>
                <span class="badge <%= ex.isActive() ? "badge-active" : "badge-inactive" %>"><%= ex.isActive() ? "Active" : "Inactive" %></span>
              </td>
              <td>
                <a href="<%= request.getContextPath() %>/jsp/teacher/questionBank.jsp?examId=<%= ex.getId() %>" class="btn btn-ghost btn-sm">
                  <i data-lucide="list-checks"></i>
                  <span>Questions</span>
                </a>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Recent Attempts -->
    <div class="card">
      <div class="card-header">
        <h3>Recent Attempts</h3>
        <a href="<%= request.getContextPath() %>/jsp/teacher/allAttempts.jsp" class="btn btn-ghost btn-sm">View All</a>
      </div>
      <div class="table-wrap" style="border:none">
        <table>
          <thead>
            <tr><th>Student</th><th>Exam</th><th>Score</th><th>Accuracy</th></tr>
          </thead>
          <tbody>
            <% if (recentAttempts.isEmpty()) { %>
            <tr><td colspan="4">
              <div class="empty-state" style="padding:30px">
                <div class="empty-state-icon"><i data-lucide="chart-column"></i></div>
                <h3>No attempts yet</h3>
              </div>
            </td></tr>
            <% } %>

            <% for (ExamAttempt at : recentAttempts.subList(0, Math.min(5, recentAttempts.size()))) { %>
            <tr>
              <td><strong><%= at.getStudentName() %></strong></td>
              <td style="font-size:0.85rem;color:#64748b"><%= at.getExamTitle() %></td>
              <td><strong><%= String.format("%.1f", at.getScore()) %></strong></td>
              <td>
                <div style="display:flex;align-items:center;gap:8px">
                  <div class="acc-bar" style="flex:1;height:5px">
                    <div class="acc-bar-fill" style="width:<%= (int)at.getAccuracy() %>%;background:<%= at.getAccuracy() >= 70 ? "#10b981" : at.getAccuracy() >= 40 ? "#f59e0b" : "#f43f5e" %>"></div>
                  </div>
                  <span style="font-size:0.8rem;font-weight:600"><%= String.format("%.0f", at.getAccuracy()) %>%</span>
                </div>
              </td>
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
