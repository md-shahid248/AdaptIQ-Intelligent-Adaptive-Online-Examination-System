<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!"Teacher".equals(currentUser.getRole()) && !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    List<ExamAttempt> attempts = new AttemptDAO().getAllAttemptsForTeacher(currentUser.getId());
    List<Exam> myExams = new ExamDAO().getExamsByTeacher(currentUser.getId());
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "All Attempts — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div><h1>All Student Attempts</h1><p>Complete attempt history across all your exams</p></div>
    <div style="display:flex;gap:10px;align-items:center">
      <select id="filterExam" onchange="filterTable()" style="padding:8px 12px;border:1.5px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:0.875rem">
        <option value="">All Exams</option>
        <% for (Exam ex : myExams) { %>
        <option value="<%= ex.getTitle() %>"><%= ex.getTitle() %></option>
        <% } %>
      </select>
      <input id="filterSearch" onkeyup="filterTable()" type="text" placeholder="Search student..." style="padding:8px 12px;border:1.5px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:0.875rem;width:180px">
    </div>
  </div>

  <div class="card">
    <div class="card-header">
      <h3>Attempts (<%= attempts.size() %>)</h3>
      <div style="font-size:0.85rem;color:#64748b">
        Avg Accuracy: <strong>
        <%
          double avgAcc = attempts.stream().mapToDouble(ExamAttempt::getAccuracy).average().orElse(0);
          out.print(String.format("%.1f%%", avgAcc));
        %>
        </strong>
      </div>
    </div>
    <div class="table-wrap" style="border:none">
      <table id="attemptsTable">
        <thead>
          <tr><th>#</th><th>Student</th><th>Exam</th><th>Score</th><th>Accuracy</th><th>Difficulty Mix</th><th>Status</th><th>Date</th><th>Detail</th></tr>
        </thead>
        <tbody>
          <% if (attempts.isEmpty()) { %>
          <tr><td colspan="9"><div class="empty-state" style="padding:60px">
            <div class="empty-state-icon"><i data-lucide="chart-column" style="width:48px;height:48px"></i></div>
            <h3>No attempts yet</h3>
            <p>Students haven't attempted any of your exams yet.</p>
          </div></td></tr>
          <% } %>
          <% int idx = 1; for (ExamAttempt a : attempts) { %>
          <tr>
            <td style="color:#94a3b8;font-size:0.82rem"><%= idx++ %></td>
            <td>
              <div style="display:flex;align-items:center;gap:8px">
                <div class="avatar-circle" style="width:30px;height:30px;font-size:0.75rem;flex-shrink:0">
                  <%= a.getStudentName() != null && a.getStudentName().length()>=2 ? a.getStudentName().substring(0,2).toUpperCase() : "??" %>
                </div>
                <strong><%= a.getStudentName() != null ? a.getStudentName() : "—" %></strong>
              </div>
            </td>
            <td style="font-size:0.875rem;color:#64748b;max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"><%= a.getExamTitle() != null ? a.getExamTitle() : "—" %></td>
            <td><strong><%= String.format("%.1f", a.getScore()) %></strong></td>
            <td>
              <div style="display:flex;align-items:center;gap:8px;min-width:100px">
                <div class="acc-bar" style="flex:1;height:5px">
                  <div class="acc-bar-fill" style="width:<%= Math.min(100,(int)a.getAccuracy()) %>%;background:<%= a.getAccuracy()>=70?"#10b981":a.getAccuracy()>=40?"#f59e0b":"#f43f5e" %>"></div>
                </div>
                <span style="font-size:0.82rem;font-weight:700;white-space:nowrap"><%= String.format("%.0f",a.getAccuracy()) %>%</span>
              </div>
            </td>
            <td style="font-size:0.78rem;color:#64748b;font-family:monospace"><%= a.getDifficultySummary() != null ? a.getDifficultySummary() : "—" %></td>
            <td>
              <span class="badge <%= "Auto-Submitted".equals(a.getStatus()) ? "badge-hard" : "badge-active" %>">
                <%= a.getStatus() %>
              </span>
            </td>
            <td style="font-size:0.8rem;color:#94a3b8;white-space:nowrap"><%= a.getDateTime() != null ? a.getDateTime().toString().substring(0,16) : "—" %></td>
            <td>
              <a href="<%= request.getContextPath() %>/jsp/teacher/attemptDetail.jsp?attemptId=<%= a.getAttemptId() %>" class="btn btn-ghost btn-sm">View</a>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
lucide.createIcons();

function filterTable() {
  const examVal   = document.getElementById('filterExam').value.toLowerCase();
  const searchVal = document.getElementById('filterSearch').value.toLowerCase();
  const rows = document.querySelectorAll('#attemptsTable tbody tr');
  rows.forEach(row => {
    const text = row.textContent.toLowerCase();
    const show = (!examVal || text.includes(examVal)) && (!searchVal || text.includes(searchVal));
    row.style.display = show ? '' : 'none';
  });
}
</script>
</body>
</html>
