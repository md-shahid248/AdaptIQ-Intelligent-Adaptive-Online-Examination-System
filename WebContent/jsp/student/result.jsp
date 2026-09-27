<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    String score        = (String) request.getAttribute("score");
    String maxPossible  = (String) request.getAttribute("maxPossible");
    String accuracy     = (String) request.getAttribute("accuracy");
    String status       = (String) request.getAttribute("status");
    Integer totalAnswered = (Integer) request.getAttribute("totalAnswered");
    Integer totalCorrect  = (Integer) request.getAttribute("totalCorrect");
    Integer easyCount   = (Integer) request.getAttribute("easyCount");
    Integer mediumCount = (Integer) request.getAttribute("mediumCount");
    Integer hardCount   = (Integer) request.getAttribute("hardCount");
    Integer attemptId   = (Integer) request.getAttribute("attemptId");

    if (score == null) { response.sendRedirect(request.getContextPath() + "/jsp/student/dashboard.jsp"); return; }

    double scoreDbl = Double.parseDouble(score);
    double maxDbl   = Double.parseDouble(maxPossible);
    double pct      = maxDbl > 0 ? (scoreDbl / maxDbl) * 100.0 : 0;
    int pctInt = (int) Math.round(pct);
    int totalAns = totalAnswered != null ? totalAnswered : 0;
    int totCorr  = totalCorrect  != null ? totalCorrect  : 0;
    int incorrect = totalAns - totCorr;

    String grade, gradeColor, gradeMsg;
    if (pctInt >= 90)      { grade="A+"; gradeColor="#10b981"; gradeMsg="Outstanding! Exceptional performance!"; }
    else if (pctInt >= 75) { grade="A";  gradeColor="#10b981"; gradeMsg="Excellent work! You're doing great!"; }
    else if (pctInt >= 60) { grade="B";  gradeColor="#f59e0b"; gradeMsg="Good performance! Keep it up!"; }
    else if (pctInt >= 45) { grade="C";  gradeColor="#f59e0b"; gradeMsg="Decent effort! More practice needed."; }
    else                   { grade="D";  gradeColor="#f43f5e"; gradeMsg="Needs improvement. Don't give up!"; }

    boolean autoSub = "Auto-Submitted".equals(status);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle",  "Exam Result — AdaptExam");
    request.setAttribute("useMono",    Boolean.TRUE);
    request.setAttribute("useChartJs", Boolean.TRUE);
    request.setAttribute("useLucide",  Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>

<% if (autoSub) { %>
<div style="background:#fef2f2;border-bottom:2px solid #f43f5e;padding:12px 24px;text-align:center;font-weight:700;color:#9f1239;font-size:0.9rem">
  <i data-lucide="triangle-alert" style="width:16px;height:16px;vertical-align:-3px"></i> This exam was auto-submitted due to policy violations or timer expiry.
</div>
<% } %>

<!-- Hero Result Banner -->
<div class="result-hero">
  <div style="max-width:700px;margin:0 auto">
    <div style="font-size:0.85rem;color:#94a3b8;font-weight:600;letter-spacing:0.08em;text-transform:uppercase;margin-bottom:16px">Exam Complete</div>

    <!-- Animated Score Ring -->
    <div class="score-ring" style="--pct:<%= pctInt * 3.6 %>deg">
      <div class="score-ring-inner">
        <div class="score-pct"><%= pctInt %>%</div>
        <div class="score-label">Score</div>
      </div>
    </div>

    <div style="font-size:3rem;font-weight:800;color:<%= gradeColor %>;margin:8px 0;font-family:'JetBrains Mono',monospace"><%= grade %></div>
    <p style="color:#94a3b8;font-size:1rem;margin-bottom:24px"><%= gradeMsg %></p>

    <div style="display:flex;justify-content:center;gap:32px;flex-wrap:wrap">
      <div style="text-align:center">
        <div style="font-size:1.8rem;font-weight:800;color:white"><%= score %></div>
        <div style="font-size:0.78rem;color:#64748b;text-transform:uppercase;letter-spacing:0.06em">Score</div>
      </div>
      <div style="text-align:center">
        <div style="font-size:1.8rem;font-weight:800;color:white"><%= maxPossible %></div>
        <div style="font-size:0.78rem;color:#64748b;text-transform:uppercase;letter-spacing:0.06em">Max Possible</div>
      </div>
      <div style="text-align:center">
        <div style="font-size:1.8rem;font-weight:800;color:white"><%= accuracy %>%</div>
        <div style="font-size:0.78rem;color:#64748b;text-transform:uppercase;letter-spacing:0.06em">Accuracy</div>
      </div>
      <div style="text-align:center">
        <div style="font-size:1.8rem;font-weight:800;color:white"><%= totalAns %></div>
        <div style="font-size:0.78rem;color:#64748b;text-transform:uppercase;letter-spacing:0.06em">Attempted</div>
      </div>
    </div>
  </div>
</div>

<div class="page-container">
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:20px;margin-bottom:28px">

    <!-- Correctness Chart -->
    <div class="chart-card card">
      <h3>Correctness</h3>
      <canvas id="correctChart" height="200"></canvas>
    </div>

    <!-- Difficulty Mix Chart -->
    <div class="chart-card card">
      <h3>Difficulty Mix</h3>
      <canvas id="diffMixChart" height="200"></canvas>
    </div>

    <!-- Performance Breakdown -->
    <div class="card card-body" style="padding:24px">
      <h3 style="font-size:0.95rem;font-weight:700;margin-bottom:16px">Performance Breakdown</h3>
      <div style="display:flex;flex-direction:column;gap:14px">
        <div>
          <div style="display:flex;justify-content:space-between;font-size:0.82rem;margin-bottom:5px">
            <span style="font-weight:600;color:#10b981"><i data-lucide="circle-check" style="width:14px;height:14px;vertical-align:-2px"></i> Correct</span>
            <span style="font-weight:700"><%= totCorr %></span>
          </div>
          <div style="height:7px;background:#f1f5f9;border-radius:4px;overflow:hidden">
            <div style="width:<%= totalAns>0?(totCorr*100/totalAns):0 %>%;height:100%;background:#10b981;border-radius:4px"></div>
          </div>
        </div>
        <div>
          <div style="display:flex;justify-content:space-between;font-size:0.82rem;margin-bottom:5px">
            <span style="font-weight:600;color:#f43f5e"><i data-lucide="circle-x" style="width:14px;height:14px;vertical-align:-2px"></i> Incorrect</span>
            <span style="font-weight:700"><%= incorrect %></span>
          </div>
          <div style="height:7px;background:#f1f5f9;border-radius:4px;overflow:hidden">
            <div style="width:<%= totalAns>0?(incorrect*100/totalAns):0 %>%;height:100%;background:#f43f5e;border-radius:4px"></div>
          </div>
        </div>
        <div style="margin-top:8px;padding-top:12px;border-top:1px solid #f1f5f9;font-size:0.82rem">
          <div style="display:flex;justify-content:space-between;margin-bottom:6px">
            <span style="color:#94a3b8">Easy Questions</span><span style="font-weight:700"><%= easyCount != null ? easyCount : 0 %></span>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:6px">
            <span style="color:#94a3b8">Medium Questions</span><span style="font-weight:700"><%= mediumCount != null ? mediumCount : 0 %></span>
          </div>
          <div style="display:flex;justify-content:space-between">
            <span style="color:#94a3b8">Hard Questions</span><span style="font-weight:700"><%= hardCount != null ? hardCount : 0 %></span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div style="display:flex;gap:14px;justify-content:center;flex-wrap:wrap">
    <a href="<%= request.getContextPath() %>/jsp/student/dashboard.jsp" class="btn btn-primary btn-lg"><i data-lucide="arrow-left" style="width:18px;height:18px"></i>Back to Dashboard</a>
    <a href="<%= request.getContextPath() %>/jsp/student/history.jsp"   class="btn btn-amber btn-lg"><i data-lucide="clipboard-list" style="width:18px;height:18px"></i>View Full History</a>
    <a href="<%= request.getContextPath() %>/jsp/student/analytics.jsp" class="btn btn-ghost btn-lg"><i data-lucide="chart-column" style="width:18px;height:18px"></i>My Analytics</a>
    <% if (attemptId != null) { %>
    <a href="<%= request.getContextPath() %>/jsp/student/leaderboard.jsp" class="btn btn-ghost btn-lg"><i data-lucide="trophy" style="width:18px;height:18px"></i>Leaderboard</a>
    <% } %>
  </div>
</div>

<script>
lucide.createIcons();

new Chart(document.getElementById('correctChart'), {
  type: 'doughnut',
  data: {
    labels: ['Correct', 'Incorrect'],
    datasets: [{ data: [<%= totCorr %>, <%= incorrect %>], backgroundColor: ['#10b981','#f43f5e'], borderWidth: 3, borderColor: '#fff' }]
  },
  options: { responsive:true, cutout:'65%', plugins:{ legend:{ position:'bottom' } } }
});

new Chart(document.getElementById('diffMixChart'), {
  type: 'doughnut',
  data: {
    labels: ['Easy', 'Medium', 'Hard'],
    datasets: [{ data: [<%= easyCount!=null?easyCount:0 %>, <%= mediumCount!=null?mediumCount:0 %>, <%= hardCount!=null?hardCount:0 %>], backgroundColor: ['#10b981','#f59e0b','#f43f5e'], borderWidth: 3, borderColor: '#fff' }]
  },
  options: { responsive:true, cutout:'65%', plugins:{ legend:{ position:'bottom' } } }
});
</script>
</body>
</html>
