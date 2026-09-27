<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!"Teacher".equals(currentUser.getRole()) && !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    int examId = 0;
    try { examId = Integer.parseInt(request.getParameter("examId")); } catch (Exception e) {}
    if (examId <= 0) { response.sendRedirect(request.getContextPath() + "/jsp/teacher/manageExams.jsp"); return; }

    Exam exam = new ExamDAO().getExamById(examId);
    if (exam == null) { response.sendRedirect(request.getContextPath() + "/jsp/teacher/manageExams.jsp"); return; }

    List<ExamAttempt> attempts = new AttemptDAO().getAttemptsByExam(examId);
    double avgScore = attempts.stream().mapToDouble(ExamAttempt::getScore).average().orElse(0);
    double avgAcc   = attempts.stream().mapToDouble(ExamAttempt::getAccuracy).average().orElse(0);
    long autoSubs   = attempts.stream().filter(a -> "Auto-Submitted".equals(a.getStatus())).count();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Exam Attempts — " + exam.getTitle());
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div>
      <h1>Exam Attempts</h1>
      <p><strong><%= exam.getTitle() %></strong> · <%= exam.getSubjectName() %></p>
    </div>
    <div style="display:flex;gap:10px">
      <a href="<%= request.getContextPath() %>/jsp/teacher/questionAnalysis.jsp?examId=<%= examId %>" class="btn btn-primary">Question Analysis</a>
      <a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp" class="btn btn-ghost"><i data-lucide="arrow-left" style="width:16px;height:16px"></i>Back</a>
    </div>
  </div>

  <div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:24px">
    <div class="stat-card"><div class="stat-icon stat-icon-navy"><i data-lucide="users"></i></div><div><div class="stat-label">Total Attempts</div><div class="stat-value"><%= attempts.size() %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-amber"><i data-lucide="trending-up"></i></div><div><div class="stat-label">Avg Score</div><div class="stat-value"><%= String.format("%.1f",avgScore) %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-green"><i data-lucide="target"></i></div><div><div class="stat-label">Avg Accuracy</div><div class="stat-value"><%= String.format("%.0f",avgAcc) %>%</div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-rose"><i data-lucide="triangle-alert"></i></div><div><div class="stat-label">Auto-Submitted</div><div class="stat-value"><%= autoSubs %></div></div></div>
  </div>

  <div class="card">
    <div class="card-header"><h3>Student Results — <%= exam.getTitle() %></h3></div>
    <div class="table-wrap" style="border:none">
      <table>
        <thead><tr><th>Rank</th><th>Student</th><th>Score</th><th>Accuracy</th><th>Difficulty Mix</th><th>Status</th><th>Date/Time</th><th>Detail</th></tr></thead>
        <tbody>
          <% if (attempts.isEmpty()) { %>
          <tr><td colspan="8"><div class="empty-state" style="padding:60px"><div class="empty-state-icon"><i data-lucide="graduation-cap" style="width:48px;height:48px"></i></div><h3>No attempts yet</h3><p>No students have attempted this exam.</p></div></td></tr>
          <% } %>
          <%
            // Sort by score desc for ranking
            attempts.sort((a,b) -> Double.compare(b.getScore(), a.getScore()));
            int rank = 1;
            for (ExamAttempt a : attempts) {
          %>
          <tr>
            <td>
              <span style="font-weight:800;font-size:1rem;<%= rank==1?"color:#f59e0b":rank==2?"color:#94a3b8":rank==3?"color:#cd7c2f":"color:#cbd5e1" %>">
                <% if (rank <= 3) { %><i data-lucide="medal" style="width:18px;height:18px;vertical-align:-3px"></i><% } else { %>#<%= rank %><% } %>
              </span>
            </td>
            <td><strong><%= a.getStudentName() != null ? a.getStudentName() : "—" %></strong></td>
            <td><span style="font-size:1.1rem;font-weight:800;color:<%= a.getScore()>0?"#0f172a":"#94a3b8" %>"><%= String.format("%.1f",a.getScore()) %></span></td>
            <td>
              <div style="display:flex;align-items:center;gap:8px;min-width:110px">
                <div class="acc-bar" style="flex:1">
                  <div class="acc-bar-fill" style="width:<%= Math.min(100,(int)a.getAccuracy()) %>%;background:<%= a.getAccuracy()>=70?"#10b981":a.getAccuracy()>=40?"#f59e0b":"#f43f5e" %>"></div>
                </div>
                <span style="font-size:0.82rem;font-weight:700"><%= String.format("%.0f",a.getAccuracy()) %>%</span>
              </div>
            </td>
            <td style="font-size:0.78rem;color:#64748b;font-family:monospace"><%= a.getDifficultySummary() != null ? a.getDifficultySummary() : "—" %></td>
            <td><span class="badge <%= "Auto-Submitted".equals(a.getStatus())?"badge-hard":"badge-active" %>"><%= a.getStatus() %></span></td>
            <td style="font-size:0.8rem;color:#94a3b8"><%= a.getDateTime() != null ? a.getDateTime().toString().substring(0,16) : "—" %></td>
            <td><a href="<%= request.getContextPath() %>/jsp/teacher/attemptDetail.jsp?attemptId=<%= a.getAttemptId() %>" class="btn btn-ghost btn-sm">View</a></td>
          </tr>
          <% rank++; } %>
        </tbody>
      </table>
    </div>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>lucide.createIcons();</script>
</body>
</html>
