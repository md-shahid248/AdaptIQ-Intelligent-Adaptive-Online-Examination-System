<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Student".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        return;
    }

    ExamDAO eDao = new ExamDAO();
    List<Exam> activeExams = eDao.getActiveExams();
    List<ExamAttempt> myAttempts = new AttemptDAO().getAttemptsByStudent(currentUser.getId());

    double avgAcc   = myAttempts.stream().mapToDouble(ExamAttempt::getAccuracy).average().orElse(0);
    double avgScore = myAttempts.stream().mapToDouble(ExamAttempt::getScore).average().orElse(0);

    // IDs of exams already attempted
    Set<Integer> attemptedExamIds = new java.util.HashSet<>();
    for (ExamAttempt a : myAttempts) {
        attemptedExamIds.add(a.getExamId());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Student Dashboard — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">

  <div class="page-header">
    <div>
      <h1>Welcome, <%= currentUser.getName().split(" ")[0] %>!</h1>
      <p>Ready for today's adaptive challenge?</p>
    </div>
    <a href="<%= request.getContextPath() %>/jsp/student/analytics.jsp" class="btn btn-amber">
      <i data-lucide="chart-column"></i>
      <span>My Analytics</span>
    </a>
  </div>

  <!-- Statistics -->
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-icon stat-icon-amber"><i data-lucide="clipboard-check"></i></div>
      <div>
        <div class="stat-label">Exams Taken</div>
        <div class="stat-value"><%= myAttempts.size() %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-green"><i data-lucide="target"></i></div>
      <div>
        <div class="stat-label">Avg Accuracy</div>
        <div class="stat-value"><%= String.format("%.0f%%", avgAcc) %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-navy"><i data-lucide="star"></i></div>
      <div>
        <div class="stat-label">Avg Score</div>
        <div class="stat-value"><%= String.format("%.1f", avgScore) %></div>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon stat-icon-sky"><i data-lucide="book-open"></i></div>
      <div>
        <div class="stat-label">Available Exams</div>
        <div class="stat-value"><%= activeExams.size() %></div>
      </div>
    </div>
  </div>

  <!-- Main Dashboard -->
  <div style="display:grid;grid-template-columns:1fr 360px;gap:24px;align-items:start">

    <!-- Available Exams -->
    <div>
      <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:14px;color:#334155">Available Exams</h2>

      <% if (activeExams.isEmpty()) { %>
      <div class="card">
        <div class="empty-state" style="padding:60px">
          <div class="empty-state-icon"><i data-lucide="inbox"></i></div>
          <h3>No exams available</h3>
          <p>Check back later!</p>
        </div>
      </div>
      <% } %>

      <div style="display:flex;flex-direction:column;gap:14px">
        <% for (Exam ex : activeExams) {
            boolean taken = attemptedExamIds.contains(ex.getId());
            Map<String,Double> marks = eDao.getDifficultyMarks(ex.getId());
        %>
        <div class="card" style="overflow:visible">
          <div style="padding:20px 24px">
            <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px">
              <div style="flex:1">

                <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px">
                  <h3 style="font-size:1rem;font-weight:700"><%= ex.getTitle() %></h3>
                  <% if (taken) { %><span class="badge badge-active">Attempted</span><% } %>
                </div>

                <p style="color:#64748b;font-size:0.875rem;margin-bottom:12px"><%= ex.getSubjectName() %></p>

                <div style="display:flex;gap:16px;font-size:0.82rem;color:#94a3b8;flex-wrap:wrap">
                  <span style="display:inline-flex;align-items:center;gap:5px">
                    <i data-lucide="clock"></i> <%= ex.getDurationMins() %> minutes
                  </span>
                  <span style="display:inline-flex;align-items:center;gap:5px">
                    <i data-lucide="circle-help"></i> <%= ex.getTotalQuestions() %> questions
                  </span>
                  <span style="display:inline-flex;align-items:center;gap:5px">
                    <i data-lucide="check-circle-2"></i> Easy: <strong style="color:#065f46"><%= marks.get("Easy") %>pt</strong>
                  </span>
                  <span style="display:inline-flex;align-items:center;gap:5px">
                    <i data-lucide="zap"></i> Medium: <strong style="color:#92400e"><%= marks.get("Medium") %>pt</strong>
                  </span>
                  <span style="display:inline-flex;align-items:center;gap:5px">
                    <i data-lucide="flame"></i> Hard: <strong style="color:#9f1239"><%= marks.get("Hard") %>pt</strong>
                  </span>
                </div>

              </div>

              <div style="flex-shrink:0">
                <% if (taken) { %>
                <a href="<%= request.getContextPath() %>/jsp/student/history.jsp" class="btn btn-ghost">
                  <i data-lucide="file-bar-chart"></i>
                  <span>View Results</span>
                </a>
                <% } %>
                <form action="<%= request.getContextPath() %>/exam" method="POST" style="margin:0;display:inline">
                  <input type="hidden" name="action" value="start">
                  <input type="hidden" name="examId" value="<%= ex.getId() %>">
                  <button type="submit" class="btn btn-amber btn-lg" style="<%= taken ? "margin-left:8px" : "" %>">
                    <i data-lucide="<%= taken ? "rotate-ccw" : "arrow-right" %>"></i>
                    <span><%= taken ? "Retake Exam" : "Start Exam" %></span>
                  </button>
                </form>
              </div>

            </div>
          </div>
        </div>
        <% } %>
      </div>
    </div>

    <!-- Recent Activity -->
    <div>
      <h2 style="font-size:1.1rem;font-weight:700;margin-bottom:14px;color:#334155">Recent Results</h2>

      <div class="card">
        <% if (myAttempts.isEmpty()) { %>
        <div class="empty-state" style="padding:40px">
          <div class="empty-state-icon"><i data-lucide="graduation-cap"></i></div>
          <h3>No exams yet</h3>
          <p>Take your first exam!</p>
        </div>
        <% } else { %>

        <div style="display:flex;flex-direction:column">
          <% for (ExamAttempt a : myAttempts.subList(0, Math.min(5, myAttempts.size()))) { %>
          <div style="padding:14px 18px;border-bottom:1px solid #f1f5f9;display:flex;align-items:center;gap:12px">

            <!-- Accuracy Circle -->
            <div style="width:42px;height:42px;border-radius:50%;background:conic-gradient(<%= a.getAccuracy() >= 70 ? "#10b981" : a.getAccuracy() >= 40 ? "#f59e0b" : "#f43f5e" %> <%= (int)a.getAccuracy() * 3.6 %>deg,#f1f5f9 0);display:flex;align-items:center;justify-content:center;flex-shrink:0">
              <div style="width:32px;height:32px;background:white;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:0.72rem;font-weight:800;color:#0f172a">
                <%= String.format("%.0f", a.getAccuracy()) %>%
              </div>
            </div>

            <div style="flex:1;min-width:0">
              <div style="font-weight:600;font-size:0.875rem;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                <%= a.getExamTitle() != null ? a.getExamTitle() : "Exam" %>
              </div>
              <div style="font-size:0.78rem;color:#94a3b8">
                <%= a.getDateTime() != null ? a.getDateTime().toString().substring(0,10) : "" %>
                · Score: <strong><%= String.format("%.1f", a.getScore()) %></strong>
              </div>
            </div>

            <% if ("Auto-Submitted".equals(a.getStatus())) { %>
            <span title="Auto-submitted" style="display:flex;align-items:center;justify-content:center">
              <i data-lucide="triangle-alert"></i>
            </span>
            <% } %>

          </div>
          <% } %>
        </div>

        <div style="padding:12px 18px;border-top:1px solid #f1f5f9;text-align:center">
          <a href="<%= request.getContextPath() %>/jsp/student/history.jsp"
             style="font-size:0.875rem;color:#1e3a72;font-weight:600;text-decoration:none;display:inline-flex;align-items:center;gap:5px">
            <span>View full history</span>
            <i data-lucide="arrow-right"></i>
          </a>
        </div>
        <% } %>
      </div>
    </div>

  </div>
</div>

<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>
  lucide.createIcons({ attrs: { 'stroke-width': 2 } });
</script>
</body>
</html>
