<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    Question q = (Question) session.getAttribute("currentQuestion");
    if (q == null) {
        response.sendRedirect(request.getContextPath() + "/jsp/student/dashboard.jsp"); return;
    }
    Exam exam = (Exam) session.getAttribute("examObj");
    int questionNumber = session.getAttribute("questionNumber") != null ? (int) session.getAttribute("questionNumber") : 1;
    int totalQ = exam != null ? exam.getTotalQuestions() : 20;
    int durationSecs = exam != null ? exam.getDurationMins() * 60 : 1800;
    int progressPct = (int) Math.round((questionNumber - 1.0) / totalQ * 100);
    String diff = q.getDifficulty();
    String diffBadge = "Easy".equals(diff) ? "badge-easy" : "Hard".equals(diff) ? "badge-hard" : "badge-medium";
    String diffIcon = "Easy".equals(diff) ? "circle-check" : "Hard".equals(diff) ? "flame" : "zap";

    // Option letters paired with their text, rendered in fixed A–D order
    char[] opts = {'A','B','C','D'};
    String[] optTexts = {q.getOptionA(), q.getOptionB(), q.getOptionC(), q.getOptionD()};
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Exam in Progress — AdaptExam");
    request.setAttribute("useMono",   Boolean.TRUE);
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
  <style>
    body { background: var(--navy-950); user-select: none; -webkit-user-select: none; }
    .option-item:has(input:checked) { border-color: #1e3a72; background: rgba(30,58,114,0.06); }
    .option-item:has(input:checked) .option-letter { background: #1e3a72; color: white; }
  </style>
</head>
<body oncontextmenu="return false;">

<!-- Exam Top Bar -->
<div class="exam-topbar">
  <div style="display:flex;align-items:center;gap:12px">
    <div class="navbar-logo" style="width:30px;height:30px;font-size:14px">AE</div>
    <div>
      <div style="font-size:0.75rem;color:#94a3b8;font-weight:600">ADAPTIVE EXAM</div>
      <div style="font-size:0.875rem;font-weight:700;color:white"><%= exam != null ? exam.getTitle() : "Exam" %></div>
    </div>
  </div>

  <div class="exam-progress-wrap">
    <div class="exam-progress-label">
      <span>Question <%= questionNumber %> of <%= totalQ %></span>
      <span><%= progressPct %>% complete</span>
    </div>
    <div class="progress-bar">
      <div class="progress-fill" style="width:<%= progressPct %>%"></div>
    </div>
  </div>

  <div id="examTimer" class="exam-timer">--:--</div>
</div>

<!-- Exam Body -->
<div class="exam-body">
  <div class="question-card">
    <div class="question-meta">
      <span class="q-number">Question <%= questionNumber %></span>
      <span class="badge <%= diffBadge %>"><i data-lucide="<%= diffIcon %>" style="width:12px;height:12px"></i><%= diff %></span>
      <% if (q.getTopic() != null && !q.getTopic().isEmpty()) { %>
      <span class="badge badge-navy"><%= q.getTopic() %></span>
      <% } %>
      <span style="margin-left:auto;font-size:0.78rem;color:#94a3b8">Adaptive Mode</span>
    </div>

    <p class="question-text"><%= q.getQuestionText() %></p>

    <form id="examForm" action="<%= request.getContextPath() %>/exam" method="POST">
      <input type="hidden" name="action" value="answer">

      <div class="options-list">
        <% for (int i = 0; i < 4; i++) { %>
        <label class="option-item">
          <input type="radio" name="answer" value="<%= opts[i] %>" required>
          <div class="option-letter"><%= opts[i] %></div>
          <span class="option-text"><%= optTexts[i] %></span>
        </label>
        <% } %>
      </div>

      <div class="exam-actions">
        <div style="font-size:0.82rem;color:#94a3b8">
          <i data-lucide="brain" style="width:14px;height:14px;vertical-align:-2px"></i> Difficulty adjusts based on your answer
        </div>
        <div style="display:flex;gap:10px">
          <button type="button" onclick="handleSubmitFinal()" class="btn btn-ghost" style="color:#94a3b8">
            Submit Exam
          </button>
          <button type="submit" class="btn btn-amber btn-lg">
            Next Question <i data-lucide="arrow-right" style="width:18px;height:18px"></i>
          </button>
        </div>
      </div>
    </form>
  </div>
</div>

<!-- Auto-submit form (hidden) -->
<form id="autoSubmitForm" action="<%= request.getContextPath() %>/exam" method="POST" style="display:none">
  <input type="hidden" name="action" value="autosubmit">
</form>

<!-- Final submit form (hidden) -->
<form id="finalSubmitForm" action="<%= request.getContextPath() %>/exam" method="POST" style="display:none">
  <input type="hidden" name="action" value="submit">
</form>

<!-- Warning Modal -->
<div id="warningModal" class="modal-overlay hidden">
  <div class="modal-box">
    <div style="margin-bottom:8px" id="modalIcon"><i data-lucide="triangle-alert" style="width:48px;height:48px;color:#f59e0b"></i></div>
    <h2 id="modalTitle">Warning</h2>
    <p id="modalMessage"></p>
    <button class="btn btn-primary btn-lg btn-full" id="modalBtn" onclick="closeWarningModal()">
      OK, I Understand
    </button>
  </div>
</div>

<!-- Confirm Submit Modal -->
<div id="confirmModal" class="modal-overlay hidden">
  <div class="modal-box">
    <div style="margin-bottom:8px"><i data-lucide="flag" style="width:48px;height:48px"></i></div>
    <h2>Submit Exam?</h2>
    <p>You have answered <span id="confirmedCount"><%= questionNumber - 1 %></span> question(s). Are you sure you want to submit now?</p>
    <div style="display:flex;gap:12px;margin-top:8px">
      <button class="btn btn-ghost btn-full" onclick="document.getElementById('confirmModal').classList.add('hidden')">Cancel</button>
      <button class="btn btn-amber btn-full" onclick="document.getElementById('finalSubmitForm').submit()">Yes, Submit</button>
    </div>
  </div>
</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
  lucide.createIcons();

  // Start timer
  startExamTimer(<%= durationSecs %>, function() {
    showWarningModal('Time\'s Up!', 'Your exam has been automatically submitted.', function() {
      document.getElementById('autoSubmitForm').submit();
    });
    setTimeout(() => document.getElementById('autoSubmitForm').submit(), 2000);
  });

  // Init anti-cheat
  initAntiCheat('autoSubmitForm');

  // Handle final submit button
  function handleSubmitFinal() {
    document.getElementById('confirmModal').classList.remove('hidden');
  }

  // Ensure one option selected before Next
  document.getElementById('examForm').addEventListener('submit', function(e) {
    const selected = document.querySelector('input[name="answer"]:checked');
    if (!selected) {
      e.preventDefault();
      showToast('Please select an answer before proceeding.', 'error');
    }
  });
</script>
</body>
</html>
