<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!"Teacher".equals(currentUser.getRole()) && !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    int attemptId = 0;
    try { attemptId = Integer.parseInt(request.getParameter("attemptId")); } catch (Exception e) {}
    if (attemptId <= 0) { response.sendRedirect(request.getContextPath() + "/jsp/teacher/allAttempts.jsp"); return; }

    AttemptDAO aDao = new AttemptDAO();
    ExamAttempt attempt = aDao.getAttemptById(attemptId);
    if (attempt == null) { response.sendRedirect(request.getContextPath() + "/jsp/teacher/allAttempts.jsp"); return; }
    List<StudentResponse> responses = aDao.getResponsesByAttempt(attemptId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Attempt Detail — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div>
      <h1>Attempt Detail</h1>
      <p><strong><%= attempt.getStudentName() %></strong> · <%= attempt.getExamTitle() %></p>
    </div>
    <a href="javascript:history.back()" class="btn btn-ghost"><i data-lucide="arrow-left" style="width:16px;height:16px"></i>Back</a>
  </div>

  <div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:24px">
    <div class="stat-card"><div class="stat-icon stat-icon-amber"><i data-lucide="target"></i></div><div><div class="stat-label">Score</div><div class="stat-value"><%= String.format("%.1f",attempt.getScore()) %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-green"><i data-lucide="circle-check"></i></div><div><div class="stat-label">Accuracy</div><div class="stat-value"><%= String.format("%.0f%%",attempt.getAccuracy()) %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-navy"><i data-lucide="clipboard-list"></i></div><div><div class="stat-label">Questions</div><div class="stat-value"><%= responses.size() %></div></div></div>
    <div class="stat-card"><div class="stat-icon <%= "Auto-Submitted".equals(attempt.getStatus())?"stat-icon-rose":"stat-icon-green" %>"><i data-lucide="<%= "Auto-Submitted".equals(attempt.getStatus())?"triangle-alert":"circle-check" %>"></i></div>
      <div><div class="stat-label">Status</div><div class="stat-value" style="font-size:1rem"><%= attempt.getStatus() %></div></div>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><h3>Question-by-Question Breakdown</h3></div>
    <div style="padding:16px;display:flex;flex-direction:column;gap:12px">
      <% int qi=1; for (StudentResponse sr : responses) {
          boolean correct = sr.isCorrect();
          String diff = sr.getDifficulty();
          String bCls = "Easy".equals(diff)?"badge-easy":"Hard".equals(diff)?"badge-hard":"badge-medium";
      %>
      <div style="border:1.5px solid <%= correct?"#a7f3d0":"#fecdd3" %>;border-radius:10px;padding:16px;background:<%= correct?"#f0fdf4":"#fff1f2" %>">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
          <i data-lucide="<%= correct?"circle-check":"circle-x" %>" style="width:20px;height:20px;flex-shrink:0;color:<%= correct?"#10b981":"#f43f5e" %>"></i>
          <span style="font-weight:800;color:#64748b;font-size:0.82rem">Q<%= qi++ %></span>
          <span class="badge <%= bCls %>"><%= diff %></span>
          <% if (sr.getTopic()!=null&&!sr.getTopic().isEmpty()) { %><span class="badge badge-navy"><%= sr.getTopic() %></span><% } %>
          <span style="margin-left:auto;font-weight:700;color:<%= correct?"#065f46":"#9f1239" %>"><%= correct ? "+"+String.format("%.1f",sr.getMarksAwarded()) : "0" %> marks</span>
        </div>
        <p style="font-weight:600;color:#0f172a;margin-bottom:8px"><%= sr.getQuestionText() %></p>
        <div style="font-size:0.85rem;color:#64748b">
          Selected: <strong style="color:<%= correct?"#065f46":"#9f1239" %>"><%= sr.getSelectedAnswer() != '\0' && sr.getSelectedAnswer() != '-' ? sr.getSelectedAnswer() : "Not answered" %></strong>
          <% if (!correct) { %> · Correct: <strong style="color:#065f46"><%= sr.getCorrectAnswer() %></strong><% } %>
        </div>
      </div>
      <% } %>
      <% if (responses.isEmpty()) { %>
      <div class="empty-state" style="padding:40px"><h3>No response data available</h3></div>
      <% } %>
    </div>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>lucide.createIcons();</script>
</body>
</html>
