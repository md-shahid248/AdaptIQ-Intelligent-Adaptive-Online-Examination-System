<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    List<Exam> activeExams = new ExamDAO().getActiveExams();
    int selectedExamId = 0;
    try { selectedExamId = Integer.parseInt(request.getParameter("examId")); } catch (Exception e) {}
    if (selectedExamId == 0 && !activeExams.isEmpty()) selectedExamId = activeExams.get(0).getId();

    List<Result> leaderboard = selectedExamId > 0
            ? new ResultDAO().getLeaderboard(selectedExamId)
            : new ArrayList<>();
    Exam selectedExam = selectedExamId > 0 ? new ExamDAO().getExamById(selectedExamId) : null;

    // Find current user's rank
    int myRank = -1;
    for (Result me : leaderboard) {
        if (me.getStudentId() == currentUser.getId()) { myRank = me.getRankInExam(); break; }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Leaderboard — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div><h1><i data-lucide="trophy" style="width:26px;height:26px;vertical-align:-3px;color:#f59e0b"></i> Leaderboard</h1><p>See how you rank among your peers</p></div>
    <form method="GET" style="display:flex;gap:10px;align-items:center">
      <select name="examId" onchange="this.form.submit()" style="padding:9px 14px;border:1.5px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:0.9rem">
        <% for (Exam ex : activeExams) { %>
        <option value="<%= ex.getId() %>" <%= ex.getId()==selectedExamId?"selected":"" %>><%= ex.getTitle() %></option>
        <% } %>
      </select>
    </form>
  </div>

  <% if (myRank > 0) { %>
  <div style="background:linear-gradient(135deg,#1a2d5a,#1e3a72);border-radius:14px;padding:20px 24px;margin-bottom:24px;color:white;display:flex;align-items:center;gap:20px">
    <div style="line-height:0"><i data-lucide="<%= myRank<=3?"medal":"target" %>" style="width:48px;height:48px<%= myRank==1?";color:#f59e0b":myRank==2?";color:#94a3b8":myRank==3?";color:#cd7c2f":"" %>"></i></div>
    <div>
      <div style="font-size:0.82rem;color:#93afd4;font-weight:600;text-transform:uppercase;letter-spacing:0.06em">Your Ranking</div>
      <div style="font-size:1.8rem;font-weight:800">Rank #<%= myRank %> of <%= leaderboard.size() %></div>
      <div style="color:#93afd4;font-size:0.9rem">in <%= selectedExam != null ? selectedExam.getTitle() : "this exam" %></div>
    </div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-header">
      <h3><%= selectedExam != null ? selectedExam.getTitle() : "Leaderboard" %></h3>
      <span style="font-size:0.85rem;color:#64748b"><%= leaderboard.size() %> participants</span>
    </div>
    <% if (leaderboard.isEmpty()) { %>
    <div class="empty-state" style="padding:80px">
      <div class="empty-state-icon"><i data-lucide="trophy" style="width:48px;height:48px"></i></div>
      <h3>No results yet</h3>
      <p>Be the first to complete this exam!</p>
      <a href="<%= request.getContextPath() %>/jsp/student/dashboard.jsp" class="btn btn-amber" style="margin-top:16px">Take Exam</a>
    </div>
    <% } else { %>
    <div class="table-wrap" style="border:none">
      <table>
        <thead>
          <tr><th>Rank</th><th>Student</th><th>Score</th><th>Max Possible</th><th>Percentage</th><th>Badge</th></tr>
        </thead>
        <tbody>
          <% for (Result r : leaderboard) {
              boolean isMe = r.getStudentId() == currentUser.getId();
              int rank = r.getRankInExam();
          %>
          <tr style="<%= isMe?"background:#fefce8;":"" %>">
            <td>
              <span style="font-size:1.2rem;font-weight:800;<%= rank==1?"color:#f59e0b":rank==2?"color:#94a3b8":rank==3?"color:#cd7c2f":"color:#cbd5e1" %>">
                <% if (rank <= 3) { %><i data-lucide="medal" style="width:20px;height:20px;vertical-align:-4px"></i> <%= rank %><% } else { %>#<%= rank %><% } %>
              </span>
            </td>
            <td>
              <div style="display:flex;align-items:center;gap:10px">
                <div class="avatar-circle" style="width:34px;height:34px;font-size:0.78rem;font-weight:800;background:<%= isMe?"#fbbf2440":"#1e3a7210" %>;color:<%= isMe?"#92400e":"#1e3a72" %>">
                  <%= r.getStudentName()!=null&&r.getStudentName().length()>=2?r.getStudentName().substring(0,2).toUpperCase():"??" %>
                </div>
                <div>
                  <strong><%= r.getStudentName() != null ? r.getStudentName() : "—" %></strong>
                  <% if (isMe) { %><span style="font-size:0.75rem;color:#f59e0b;font-weight:700;margin-left:6px">You</span><% } %>
                </div>
              </div>
            </td>
            <td><span style="font-size:1.05rem;font-weight:800"><%= String.format("%.1f",r.getTotalScore()) %></span></td>
            <td style="color:#64748b"><%= String.format("%.1f",r.getMaxPossibleScore()) %></td>
            <td>
              <div style="display:flex;align-items:center;gap:8px">
                <div class="acc-bar" style="width:80px">
                  <div class="acc-bar-fill" style="width:<%= Math.min(100,(int)r.getPercentage()) %>%;background:<%= r.getPercentage()>=70?"#10b981":r.getPercentage()>=40?"#f59e0b":"#f43f5e" %>"></div>
                </div>
                <strong style="font-size:0.9rem"><%= String.format("%.1f%%",r.getPercentage()) %></strong>
              </div>
            </td>
            <td>
              <%
                double pct = r.getPercentage();
                String badgeIcon  = pct>=90?"trophy":pct>=75?"star":pct>=60?"thumbs-up":pct>=45?"book-open":"dumbbell";
                String badgeLabel = pct>=90?"Champion":pct>=75?"Excellent":pct>=60?"Good":pct>=45?"Average":"Keep Going";
              %>
              <span style="font-size:0.82rem"><i data-lucide="<%= badgeIcon %>" style="width:14px;height:14px;vertical-align:-2px"></i> <%= badgeLabel %></span>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
    <% } %>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>lucide.createIcons();</script>
</body>
</html>
