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
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle",  "Question Analysis — AdaptExam");
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
      <h1>Question Performance Analysis</h1>
      <p><strong><%= exam.getTitle() %></strong> · Success rate per question</p>
    </div>
    <a href="<%= request.getContextPath() %>/jsp/teacher/examAttempts.jsp?examId=<%= examId %>" class="btn btn-ghost"><i data-lucide="arrow-left" style="width:16px;height:16px"></i>Attempts</a>
  </div>

  <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:24px">
    <div class="chart-card card">
      <h3>Success Rate by Difficulty</h3>
      <canvas id="diffRateChart" height="220"></canvas>
    </div>
    <div class="chart-card card">
      <h3>Hardest Questions (Lowest Success Rate)</h3>
      <canvas id="hardestChart" height="220"></canvas>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><h3>All Questions — Detailed Performance</h3></div>
    <div id="questionsTable" class="table-wrap" style="border:none">
      <div style="padding:40px;text-align:center;color:#94a3b8">Loading analysis…</div>
    </div>
  </div>
</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
lucide.createIcons();

fetch('<%= request.getContextPath() %>/analytics?type=questionPerf&examId=<%= examId %>')
  .then(r => r.json())
  .then(data => {
    const qs = data.questions || [];

    if (qs.length === 0) {
      document.getElementById('questionsTable').innerHTML =
        '<div class="empty-state" style="padding:60px"><div class="empty-state-icon"><i data-lucide="circle-help" style="width:48px;height:48px"></i></div><h3>No attempt data yet</h3><p>Students must attempt this exam for analysis to appear.</p></div>';
      renderIcons();
      return;
    }

    // Group by difficulty for chart 1
    const diffMap = {Easy:{total:0,correct:0}, Medium:{total:0,correct:0}, Hard:{total:0,correct:0}};
    qs.forEach(q => {
      if (diffMap[q.difficulty]) {
        diffMap[q.difficulty].total   += q.total;
        diffMap[q.difficulty].correct += q.correct;
      }
    });
    const diffRates = ['Easy','Medium','Hard'].map(d =>
      diffMap[d].total > 0 ? (diffMap[d].correct/diffMap[d].total*100).toFixed(1) : 0
    );

    new Chart(document.getElementById('diffRateChart'), {
      type: 'bar',
      data: {
        labels: ['Easy','Medium','Hard'],
        datasets: [{ label:'Success Rate %', data: diffRates,
          backgroundColor: ['#10b98122','#f59e0b22','#f43f5e22'],
          borderColor:      ['#10b981','#f59e0b','#f43f5e'],
          borderWidth: 2, borderRadius: 8 }]
      },
      options: { responsive:true, plugins:{legend:{display:false}}, scales:{y:{min:0,max:100,ticks:{callback:v=>v+'%'}}} }
    });

    // Chart 2: bottom 6 hardest questions
    const sorted = [...qs].sort((a,b) => a.rate - b.rate).slice(0, 6);
    new Chart(document.getElementById('hardestChart'), {
      type: 'bar',
      data: {
        labels: sorted.map(q => 'Q'+(qs.indexOf(q)+1)+': '+q.text.substring(0,30)+'…'),
        datasets: [{ label:'Success %', data: sorted.map(q=>q.rate),
          backgroundColor: '#f43f5e22', borderColor:'#f43f5e', borderWidth:2, borderRadius:4 }]
      },
      options: { indexAxis:'y', responsive:true, plugins:{legend:{display:false}}, scales:{x:{min:0,max:100,ticks:{callback:v=>v+'%'}}} }
    });

    // Build table
    let html = '<table><thead><tr><th>#</th><th>Question</th><th>Topic</th><th>Difficulty</th><th>Attempts</th><th>Correct</th><th>Success Rate</th><th>Health</th></tr></thead><tbody>';
    qs.forEach((q,i) => {
      const rate = parseFloat(q.rate);
      const health = rate >= 70 ? 'Good' : rate >= 40 ? 'Fair' : 'Hard';
      const hColor = rate >= 70 ? '#065f46' : rate >= 40 ? '#92400e' : '#9f1239';
      const hBg    = rate >= 70 ? '#d1fae5' : rate >= 40 ? '#fef3c7' : '#ffe4e6';
      html += `<tr>
        <td style="color:#94a3b8;font-size:0.82rem">${i+1}</td>
        <td style="max-width:260px;font-size:0.875rem;font-weight:500">${q.text}</td>
        <td><span class="badge badge-navy">${q.topic||'—'}</span></td>
        <td><span class="badge ${'Easy'===q.difficulty?'badge-easy':'Hard'===q.difficulty?'badge-hard':'badge-medium'}">${q.difficulty}</span></td>
        <td style="text-align:center">${q.total}</td>
        <td style="text-align:center;color:#10b981;font-weight:700">${q.correct}</td>
        <td>
          <div style="display:flex;align-items:center;gap:8px">
            <div class="acc-bar" style="flex:1;min-width:60px">
              <div class="acc-bar-fill" style="width:${Math.min(100,rate)}%;background:${rate>=70?'#10b981':rate>=40?'#f59e0b':'#f43f5e'}"></div>
            </div>
            <span style="font-weight:700;font-size:0.85rem">${rate}%</span>
          </div>
        </td>
        <td><span style="font-size:0.78rem;font-weight:700;padding:3px 9px;border-radius:12px;background:${hBg};color:${hColor}">${health}</span></td>
      </tr>`;
    });
    html += '</tbody></table>';
    document.getElementById('questionsTable').innerHTML = html;
  });
</script>
</body>
</html>
