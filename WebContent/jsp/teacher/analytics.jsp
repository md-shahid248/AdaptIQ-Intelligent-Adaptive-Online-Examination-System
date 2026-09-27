<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!"Teacher".equals(currentUser.getRole()) && !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    List<Exam> myExams = new ExamDAO().getExamsByTeacher(currentUser.getId());
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle",  "Class Analytics — AdaptExam");
    request.setAttribute("useChartJs", Boolean.TRUE);
    request.setAttribute("useLucide",  Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div><h1>Class Analytics</h1><p>Performance overview across all your exams</p></div>
    <select id="examSelector" onchange="loadExamAnalytics()" style="padding:9px 14px;border:1.5px solid #e2e8f0;border-radius:8px;font-family:inherit;font-size:0.9rem">
      <option value="">— Select Exam —</option>
      <% for (Exam ex : myExams) { %>
      <option value="<%= ex.getId() %>"><%= ex.getTitle() %></option>
      <% } %>
    </select>
  </div>

  <!-- Class-wide charts (all exams) -->
  <div id="overviewSection">
    <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:16px;color:#475569">All Exams Overview</h2>
    <div class="charts-grid" style="grid-template-columns:1fr 1fr">
      <div class="chart-card">
        <h3>Average Score % per Exam</h3>
        <canvas id="avgScoreChart" height="200"></canvas>
      </div>
      <div class="chart-card">
        <h3>Attempts per Exam</h3>
        <canvas id="attemptsChart" height="200"></canvas>
      </div>
    </div>
  </div>

  <!-- Per-exam section (shown when exam selected) -->
  <div id="examSection" style="display:none;margin-top:28px">
    <h2 id="examSectionTitle" style="font-size:1.1rem;font-weight:700;margin-bottom:16px;color:#475569"></h2>
    <div class="charts-grid" style="grid-template-columns:1fr 1fr 1fr">
      <div class="chart-card"><h3>Score Distribution</h3><canvas id="scoreDistChart" height="220"></canvas></div>
      <div class="chart-card"><h3>Accuracy Distribution</h3><canvas id="accDistChart" height="220"></canvas></div>
      <div class="chart-card"><h3>Submission Status</h3><canvas id="statusChart" height="220"></canvas></div>
    </div>
    <div style="margin-top:20px">
      <div class="card">
        <div class="card-header"><h3 id="leaderTitle">Leaderboard</h3></div>
        <div id="leaderBody" class="table-wrap" style="border:none"></div>
      </div>
    </div>
  </div>
</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
lucide.createIcons();

let overviewChart1 = null, overviewChart2 = null;
let examCharts = [];

// Load overview on page load
fetch('<%= request.getContextPath() %>/analytics?type=teacher')
  .then(r => r.json())
  .then(data => {
    const exams = data.exams || [];
    const labels   = exams.map(e => e.title.length > 20 ? e.title.substring(0,20)+'…' : e.title);
    const avgPcts  = exams.map(e => e.avgPct);
    const attempts = exams.map(e => e.attempts);

    if (overviewChart1) overviewChart1.destroy();
    if (overviewChart2) overviewChart2.destroy();

    overviewChart1 = new Chart(document.getElementById('avgScoreChart'), {
      type: 'bar',
      data: {
        labels,
        datasets: [{ label: 'Avg Score %', data: avgPcts,
          backgroundColor: '#1e3a7222', borderColor: '#1e3a72', borderWidth: 2, borderRadius: 6 }]
      },
      options: { responsive: true, plugins:{legend:{display:false}}, scales:{ y:{ min:0, max:100, ticks:{callback:v=>v+'%'} } } }
    });

    overviewChart2 = new Chart(document.getElementById('attemptsChart'), {
      type: 'bar',
      data: {
        labels,
        datasets: [{ label: 'Attempts', data: attempts,
          backgroundColor: '#f59e0b22', borderColor: '#f59e0b', borderWidth: 2, borderRadius: 6 }]
      },
      options: { responsive: true, plugins:{legend:{display:false}}, scales:{ y:{ beginAtZero:true, ticks:{stepSize:1} } } }
    });
  });

function loadExamAnalytics() {
  const examId = document.getElementById('examSelector').value;
  if (!examId) { document.getElementById('examSection').style.display='none'; return; }

  // Destroy old charts
  examCharts.forEach(c => c && c.destroy());
  examCharts = [];

  const title = document.getElementById('examSelector').selectedOptions[0].text;
  document.getElementById('examSectionTitle').textContent = 'Exam: ' + title;
  document.getElementById('examSection').style.display = 'block';
  document.getElementById('leaderTitle').textContent = 'Leaderboard — ' + title;

  fetch('<%= request.getContextPath() %>/analytics?type=teacher&examId=' + examId)
    .then(r => r.json())
    .then(data => {
      const exams = data.exams || [];
      const ex = exams[0] || {};

      // Simple placeholder charts using available data
      const scoreData  = [ex.minScore||0, ex.avgPct||0, ex.maxScore||0];
      const scoreLabels = ['Min Score', 'Avg Score', 'Max Score'];

      examCharts[0] = new Chart(document.getElementById('scoreDistChart'), {
        type: 'bar',
        data: { labels: scoreLabels, datasets: [{ data: scoreData, backgroundColor: ['#f43f5e44','#f59e0b44','#10b98144'], borderColor: ['#f43f5e','#f59e0b','#10b981'], borderWidth:2, borderRadius:6 }] },
        options: { responsive:true, plugins:{legend:{display:false}}, scales:{y:{beginAtZero:true}} }
      });

      examCharts[1] = new Chart(document.getElementById('accDistChart'), {
        type: 'doughnut',
        data: {
          labels: ['Avg Accuracy'],
          datasets: [{
            data: [Math.round(ex.avgPct||0), Math.max(0, 100-Math.round(ex.avgPct||0))],
            backgroundColor: ['#10b981','#f1f5f9'],
            borderWidth: 0
          }]
        },
        options: { responsive:true, cutout:'70%', plugins:{ legend:{display:false}, tooltip:{callbacks:{label:ctx=>ctx.label+': '+(ctx.dataIndex===0?Math.round(ex.avgPct||0)+'%':'')}} } }
      });

      examCharts[2] = new Chart(document.getElementById('statusChart'), {
        type: 'pie',
        data: {
          labels: ['Completed', 'Auto-Submitted'],
          datasets: [{ data: [ex.attempts||0, 0], backgroundColor: ['#10b981','#f43f5e'], borderWidth:2, borderColor:'#fff' }]
        },
        options: { responsive:true, plugins:{legend:{position:'bottom'}} }
      });
    });

  // Load leaderboard
  loadLeaderboard(examId);
}

function loadLeaderboard(examId) {
  // We'll fetch attempts and build inline
  const tbody = document.getElementById('leaderBody');
  tbody.innerHTML = '<div style="padding:20px;color:#94a3b8;text-align:center">Loading…</div>';

  fetch('<%= request.getContextPath() %>/analytics?type=teacher&examId=' + examId)
    .then(r => r.json())
    .then(() => {
      tbody.innerHTML = '<div style="padding:16px;color:#64748b;font-size:0.9rem;text-align:center">View full leaderboard on the <a href="<%= request.getContextPath() %>/jsp/teacher/examAttempts.jsp?examId=' + examId + '" style="color:#1e3a72;font-weight:600">Attempts page</a></div>';
    });
}
</script>
</body>
</html>
