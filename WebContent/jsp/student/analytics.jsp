<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle",  "My Analytics — AdaptExam");
    request.setAttribute("useChartJs", Boolean.TRUE);
    request.setAttribute("useLucide",  Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">

  <div class="page-header">
    <div>
      <h1>My Performance Analytics</h1>
      <p>Track your progress across all exams</p>
    </div>
  </div>

  <!-- Summary Cards -->
  <div class="stats-grid" id="summaryCards">
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="chart-column"></i></div>
      <div>
        <div class="stat-label">Total Exams</div>
        <div class="stat-value" id="sumExams">—</div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-green"><i data-lucide="check-circle-2"></i></div>
      <div>
        <div class="stat-label">Easy Accuracy</div>
        <div class="stat-value" id="sumEasy">—</div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="zap"></i></div>
      <div>
        <div class="stat-label">Medium Accuracy</div>
        <div class="stat-value" id="sumMedium">—</div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-rose"><i data-lucide="flame"></i></div>
      <div>
        <div class="stat-label">Hard Accuracy</div>
        <div class="stat-value" id="sumHard">—</div>
      </div>
    </div>
  </div>

  <!-- Loading State -->
  <div id="loadingState" style="text-align:center;padding:60px;color:#94a3b8">
    <div style="margin-bottom:12px;display:flex;justify-content:center">
      <i data-lucide="loader-circle" style="width:32px;height:32px;animation:spin 1s linear infinite"></i>
    </div>
    <div style="font-weight:600">Loading your analytics...</div>
  </div>

  <!-- Analytics Content -->
  <div id="analyticsContent" style="display:none">
    <div class="charts-grid" style="grid-template-columns:2fr 1fr 1fr;margin-bottom:20px">
      <div class="chart-card card">
        <h3>Score Trend (Last 8 Exams)</h3>
        <canvas id="scoreChart" height="200"></canvas>
      </div>
      <div class="chart-card card">
        <h3>Accuracy by Difficulty</h3>
        <canvas id="diffChart" height="200"></canvas>
      </div>
      <div class="chart-card card">
        <h3>Overall Correctness</h3>
        <canvas id="pieChart" height="200"></canvas>
      </div>
    </div>

    <div id="emptyState" class="empty-state" style="display:none;padding:60px">
      <div class="empty-state-icon"><i data-lucide="inbox"></i></div>
      <h3>No data yet</h3>
      <p>Complete some exams to see your analytics.</p>
      <a href="<%= request.getContextPath() %>/jsp/student/dashboard.jsp" class="btn btn-amber" style="margin-top:16px">
        <i data-lucide="play"></i>
        <span>Take an Exam</span>
      </a>
    </div>
  </div>

</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
fetch('<%= request.getContextPath() %>/analytics?type=student')
  .then(r => r.json())
  .then(data => {
    document.getElementById('loadingState').style.display = 'none';
    document.getElementById('analyticsContent').style.display = 'block';

    // Update summary cards
    document.getElementById('sumExams').textContent  = data.totalExams || 0;
    document.getElementById('sumEasy').textContent   = (data.easyAcc   || 0).toFixed(0) + '%';
    document.getElementById('sumMedium').textContent = (data.mediumAcc || 0).toFixed(0) + '%';
    document.getElementById('sumHard').textContent   = (data.hardAcc   || 0).toFixed(0) + '%';

    // Check whether analytics data exists
    const hasData = (data.totalExams || 0) > 0;
    if (!hasData) {
      document.getElementById('emptyState').style.display = 'block';
      lucide.createIcons();
      return;
    }

    // Score Trend Line Chart
    new Chart(document.getElementById('scoreChart'), {
      type: 'line',
      data: {
        labels: data.examLabels || [],
        datasets: [{
          label: 'Score %',
          data: data.scorePercents || [],
          borderColor: '#1e3a72',
          backgroundColor: 'rgba(30,58,114,0.08)',
          borderWidth: 2.5,
          pointRadius: 5,
          pointBackgroundColor: '#1e3a72',
          pointHoverRadius: 7,
          fill: true,
          tension: 0.35
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { min: 0, max: 100, ticks: { callback: v => v + '%' }, grid: { color: '#f1f5f9' } },
          x: { grid: { display: false } }
        }
      }
    });

    // Difficulty Accuracy Bar Chart
    new Chart(document.getElementById('diffChart'), {
      type: 'bar',
      data: {
        labels: ['Easy', 'Medium', 'Hard'],
        datasets: [{
          label: 'Accuracy %',
          data: [data.easyAcc || 0, data.mediumAcc || 0, data.hardAcc || 0],
          backgroundColor: ['rgba(16,185,129,0.15)', 'rgba(245,158,11,0.15)', 'rgba(244,63,94,0.15)'],
          borderColor: ['#10b981', '#f59e0b', '#f43f5e'],
          borderWidth: 2,
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { min: 0, max: 100, ticks: { callback: v => v + '%' } } }
      }
    });

    // Overall Correctness Doughnut
    new Chart(document.getElementById('pieChart'), {
      type: 'doughnut',
      data: {
        labels: ['Correct', 'Incorrect'],
        datasets: [{
          data: [data.correct || 0, data.incorrect || 0],
          backgroundColor: ['#10b981', '#f43f5e'],
          borderWidth: 3,
          borderColor: '#fff'
        }]
      },
      options: {
        responsive: true,
        cutout: '65%',
        plugins: {
          legend: { position: 'bottom' },
          tooltip: { callbacks: { label: ctx => ctx.label + ': ' + ctx.raw } }
        }
      }
    });
  })
  .catch(() => {
    document.getElementById('loadingState').innerHTML =
      '<div style="color:#f43f5e;font-weight:600;display:flex;align-items:center;justify-content:center;gap:8px">' +
      '<i data-lucide="triangle-alert"></i>' +
      '<span>Failed to load analytics. Please refresh.</span>' +
      '</div>';
    lucide.createIcons();
  });

// Initialize Lucide icons after the page loads.
lucide.createIcons();
</script>

<!-- Loading Spinner Animation (used only by #loadingState on this page) -->
<style>
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
</style>
</body>
</html>
