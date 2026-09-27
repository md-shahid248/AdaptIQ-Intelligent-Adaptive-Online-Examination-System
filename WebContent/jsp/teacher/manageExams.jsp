<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.adaptiveexam.dao.*,com.adaptiveexam.models.*,java.util.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || (!"Teacher".equals(currentUser.getRole()) && !"Admin".equals(currentUser.getRole()))) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    ExamDAO eDao = new ExamDAO();
    List<Exam> exams = eDao.getExamsByTeacher(currentUser.getId());
    List<Subject> subjects = new SubjectDAO().getAllSubjects();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Manage Exams — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div><h1>Manage Exams</h1><p>Create and configure your adaptive examinations</p></div>
  </div>

  <!-- Create Exam Form -->
  <div class="card" style="margin-bottom:24px">
    <div class="card-header" style="cursor:pointer" onclick="toggleForm()">
      <h3><i data-lucide="plus" style="width:16px;height:16px;vertical-align:-3px"></i> Create New Exam</h3>
      <span id="toggleIcon" style="color:#64748b"><i data-lucide="chevron-down" style="width:21px;height:21px"></i></span>
    </div>
    <div id="createForm" style="display:none">
      <div class="card-body">
        <form action="<%= request.getContextPath() %>/teacher" method="POST" onsubmit="return validateCreateExam()">
          <input type="hidden" name="action" value="createExam">
          <div class="form-row">
            <div class="form-group">
              <label>Exam Title *</label>
              <input type="text" id="title" name="title" placeholder="e.g. DSA Mid-Term Quiz" required>
            </div>
            <div class="form-group">
              <label>Subject *</label>
              <select id="subjectId" name="subjectId" required>
                <option value="">Select Subject</option>
                <% for (Subject s : subjects) { %>
                <option value="<%= s.getId() %>"><%= s.getName() %></option>
                <% } %>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Duration (minutes) *</label>
              <input type="number" id="durationMins" name="durationMins" value="30" min="5" max="180" required>
            </div>
            <div class="form-group">
              <label>Total Questions *</label>
              <input type="number" id="totalQuestions" name="totalQuestions" value="15" min="1" max="100" required>
            </div>
          </div>

          <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:20px;margin-bottom:20px">
            <div style="font-weight:700;margin-bottom:12px;color:#334155"><i data-lucide="chart-column" style="width:16px;height:16px;vertical-align:-3px"></i> Marks Distribution</div>
            <p style="font-size:0.85rem;color:#64748b;margin-bottom:16px">Set marks awarded per correct answer by difficulty level. Defaults: Easy=1, Medium=2, Hard=4</p>
            <div class="form-row" style="grid-template-columns:1fr 1fr 1fr">
              <div class="form-group" style="margin:0">
                <label style="color:#065f46"><i data-lucide="circle-check" style="width:14px;height:14px;vertical-align:-2px"></i> Easy Marks</label>
                <input type="number" name="easyMarks" value="1" min="0.5" max="10" step="0.5">
              </div>
              <div class="form-group" style="margin:0">
                <label style="color:#92400e"><i data-lucide="zap" style="width:14px;height:14px;vertical-align:-2px"></i> Medium Marks</label>
                <input type="number" name="mediumMarks" value="2" min="0.5" max="10" step="0.5">
              </div>
              <div class="form-group" style="margin:0">
                <label style="color:#9f1239"><i data-lucide="flame" style="width:14px;height:14px;vertical-align:-2px"></i> Hard Marks</label>
                <input type="number" name="hardMarks" value="4" min="0.5" max="10" step="0.5">
              </div>
            </div>
          </div>

          <div style="display:flex;gap:12px">
            <button type="submit" class="btn btn-amber btn-lg">Create Exam</button>
            <button type="button" class="btn btn-ghost" onclick="toggleForm()">Cancel</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- Exams Table -->
  <div class="card">
    <div class="card-header"><h3>My Exams (<%= exams.size() %>)</h3></div>
    <div class="table-wrap" style="border:none">
      <table>
        <thead>
          <tr><th>Title</th><th>Subject</th><th>Duration</th><th>Questions</th><th>Marks (E/M/H)</th><th>Status</th><th>Actions</th></tr>
        </thead>
        <tbody>
          <% if (exams.isEmpty()) { %>
          <tr><td colspan="7"><div class="empty-state" style="padding:60px">
            <div class="empty-state-icon"><i data-lucide="clipboard-list" style="width:48px;height:48px"></i></div>
            <h3>No exams created yet</h3>
            <p>Click "Create New Exam" above to get started.</p>
          </div></td></tr>
          <% } %>
          <% for (Exam ex : exams) {
              Map<String,Double> marks = eDao.getDifficultyMarks(ex.getId()); %>
          <tr>
            <td><strong><%= ex.getTitle() %></strong></td>
            <td style="font-size:0.875rem;color:#64748b"><%= ex.getSubjectName() %></td>
            <td><%= ex.getDurationMins() %> min</td>
            <td><%= ex.getTotalQuestions() %> Q</td>
            <td style="font-family:monospace;font-size:0.85rem">
              <span style="color:#065f46"><%= marks.get("Easy") %></span> /
              <span style="color:#92400e"><%= marks.get("Medium") %></span> /
              <span style="color:#9f1239"><%= marks.get("Hard") %></span>
            </td>
            <td><span class="badge <%= ex.isActive() ? "badge-active" : "badge-inactive" %>"><%= ex.isActive() ? "Active" : "Inactive" %></span></td>
            <td>
              <div style="display:flex;gap:6px;flex-wrap:wrap">
                <a href="<%= request.getContextPath() %>/jsp/teacher/questionBank.jsp?examId=<%= ex.getId() %>" class="btn btn-primary btn-sm">Questions</a>
                <a href="<%= request.getContextPath() %>/jsp/teacher/examAttempts.jsp?examId=<%= ex.getId() %>" class="btn btn-ghost btn-sm">Attempts</a>
                <a href="<%= request.getContextPath() %>/jsp/teacher/questionAnalysis.jsp?examId=<%= ex.getId() %>" class="btn btn-ghost btn-sm">Analysis</a>
                <form action="<%= request.getContextPath() %>/teacher" method="POST" style="margin:0">
                  <input type="hidden" name="action" value="toggleExam">
                  <input type="hidden" name="examId" value="<%= ex.getId() %>">
                  <button type="submit" class="btn btn-ghost btn-sm"><%= ex.isActive() ? "Deactivate" : "Activate" %></button>
                </form>
                <form id="edel-<%= ex.getId() %>" action="<%= request.getContextPath() %>/teacher" method="POST" style="margin:0">
                  <input type="hidden" name="action" value="deleteExam">
                  <input type="hidden" name="examId" value="<%= ex.getId() %>">
                  <button type="button" class="btn btn-danger btn-sm"
                    onclick="confirmDelete('edel-<%= ex.getId() %>','Delete exam &quot;<%= ex.getTitle() %>&quot;? All questions and attempts will be lost.')">
                    Delete
                  </button>
                </form>
              </div>
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

function toggleForm() {
  const form = document.getElementById('createForm');
  const icon = document.getElementById('toggleIcon');
  const showing = form.style.display !== 'none';
  form.style.display = showing ? 'none' : 'block';
  icon.innerHTML = `<i data-lucide="chevron-${showing ? 'down' : 'up'}" style="width:21px;height:21px"></i>`;
  renderIcons();
}
</script>
</body>
</html>
