<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }

    List<ExamAttempt> attempts = new AttemptDAO().getAttemptsByStudent(currentUser.getId());
    double bestScore = attempts.stream().mapToDouble(ExamAttempt::getScore).max().orElse(0);
    double avgAcc = attempts.stream().mapToDouble(ExamAttempt::getAccuracy).average().orElse(0);
    long completed = attempts.stream().filter(a -> "Completed".equals(a.getStatus())).count();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "My History — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">

  <div class="page-header">
    <div>
      <h1>My Exam History</h1>
      <p>All your past attempts and results</p>
    </div>
  </div>

  <div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:24px">
    <div class="stat-card">
      <div class="stat-icon stat-icon-navy"><i data-lucide="clipboard-list"></i></div>
      <div>
        <div class="stat-label">Total Attempts</div>
        <div class="stat-value"><%= attempts.size() %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="star"></i></div>
      <div>
        <div class="stat-label">Best Score</div>
        <div class="stat-value"><%= String.format("%.1f",bestScore) %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-green"><i data-lucide="target"></i></div>
      <div>
        <div class="stat-label">Avg Accuracy</div>
        <div class="stat-value"><%= String.format("%.0f%%",avgAcc) %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-sky"><i data-lucide="circle-check"></i></div>
      <div>
        <div class="stat-label">Completed</div>
        <div class="stat-value"><%= completed %></div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><h3>Attempt History</h3></div>

    <% if (attempts.isEmpty()) { %>
    <div class="empty-state" style="padding:80px">
      <div class="empty-state-icon"><i data-lucide="inbox"></i></div>
      <h3>No attempts yet</h3>
      <p>Take your first exam to see results here.</p>
      <a href="<%= request.getContextPath() %>/jsp/student/dashboard.jsp" class="btn btn-amber" style="margin-top:16px">
        Browse Exams
      </a>
    </div>
    <% } else { %>

    <div class="table-wrap" style="border:none">
      <table>
        <thead>
          <tr><th>#</th><th>Exam</th><th>Score</th><th>Accuracy</th><th>Questions Mix</th><th>Status</th><th>Date</th></tr>
        </thead>
        <tbody>
        <% int idx=1; for (ExamAttempt a : attempts) {
            boolean autoSub = "Auto-Submitted".equals(a.getStatus());
        %>
          <tr>
            <td style="color:#94a3b8;font-size:0.82rem"><%= idx++ %></td>
            <td><strong><%= a.getExamTitle() != null ? a.getExamTitle() : "—" %></strong></td>
            <td>
              <span style="font-size:1.05rem;font-weight:800;color:<%= a.getScore()>0?"#0f172a":"#94a3b8" %>"><%= String.format("%.1f", a.getScore()) %></span>
            </td>
            <td>
              <div style="display:flex;align-items:center;gap:8px;min-width:110px">
                <div class="acc-bar" style="flex:1">
                  <div class="acc-bar-fill" style="width:<%= Math.min(100,(int)a.getAccuracy()) %>%;background:<%= a.getAccuracy()>=70?"#10b981":a.getAccuracy()>=40?"#f59e0b":"#f43f5e" %>"></div>
                </div>
                <span style="font-size:0.82rem;font-weight:700;white-space:nowrap"><%= String.format("%.0f",a.getAccuracy()) %>%</span>
              </div>
            </td>
            <td style="font-size:0.78rem;color:#64748b;font-family:monospace">
              <%
                String ds = a.getDifficultySummary();
                if (ds != null && !ds.isEmpty()) {
                    for (String part : ds.split(",")) {
                        String[] kv = part.split(":");
                        if (kv.length == 2) {
                            String dl = kv[0].trim();
                            String cnt = kv[1].trim();
                            String dc = "Easy".equals(dl) ? "#065f46" :
                                        "Hard".equals(dl) ? "#9f1239" : "#92400e";
              %>
              <span style="color:<%= dc %>;font-weight:600"><%= dl.charAt(0) %>:<%= cnt %></span>&nbsp;
              <%
                        }
                    }
                } else {
                    out.print("—");
                }
              %>
            </td>
            <td>
              <span class="badge <%= autoSub ? "badge-hard" : "badge-active" %>">
                <i data-lucide="<%= autoSub ? "triangle-alert" : "circle-check" %>"></i>
                <%= autoSub ? "Auto" : "Done" %>
              </span>
            </td>
            <td style="font-size:0.8rem;color:#94a3b8;white-space:nowrap">
              <%= a.getDateTime() != null ? a.getDateTime().toString().substring(0,16) : "—" %>
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
<script>
  lucide.createIcons();
</script>
</body>
</html>
