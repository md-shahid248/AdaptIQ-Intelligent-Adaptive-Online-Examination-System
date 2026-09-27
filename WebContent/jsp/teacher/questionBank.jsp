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

    ExamDAO eDao = new ExamDAO();
    Exam exam = eDao.getExamById(examId);
    if (exam == null) { response.sendRedirect(request.getContextPath() + "/jsp/teacher/manageExams.jsp"); return; }

    QuestionDAO qDao = new QuestionDAO();
    List<Question> questions = qDao.getQuestionsByExam(examId);
    Map<String,Integer> counts = qDao.getQuestionCountByDifficulty(examId);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Question Bank — " + exam.getTitle());
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div>
      <h1>Question Bank</h1>
      <p><strong><%= exam.getTitle() %></strong> · <%= exam.getSubjectName() %> · <%= exam.getDurationMins() %>min · <%= exam.getTotalQuestions() %> Questions required</p>
    </div>
    <a href="<%= request.getContextPath() %>/jsp/teacher/manageExams.jsp" class="btn btn-ghost"><i data-lucide="arrow-left" style="width:16px;height:16px"></i>Back to Exams</a>
  </div>

  <div class="stats-grid" style="grid-template-columns:repeat(4,1fr);margin-bottom:20px">
    <div class="stat-card"><div class="stat-icon stat-icon-green"><i data-lucide="clipboard-list"></i></div><div><div class="stat-label">Total Q's</div><div class="stat-value"><%= questions.size() %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-green"><i data-lucide="circle-check"></i></div><div><div class="stat-label">Easy</div><div class="stat-value"><%= counts.getOrDefault("Easy",0) %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-amber"><i data-lucide="zap"></i></div><div><div class="stat-label">Medium</div><div class="stat-value"><%= counts.getOrDefault("Medium",0) %></div></div></div>
    <div class="stat-card"><div class="stat-icon stat-icon-rose"><i data-lucide="flame"></i></div><div><div class="stat-label">Hard</div><div class="stat-value"><%= counts.getOrDefault("Hard",0) %></div></div></div>
  </div>

  <div style="display:grid;grid-template-columns:380px 1fr;gap:24px;align-items:start">
    <!-- Add Question Form -->
    <div class="card" style="position:sticky;top:80px">
      <div class="card-header"><h3>Add MCQ Question</h3></div>
      <div class="card-body">
        <form action="<%= request.getContextPath() %>/teacher" method="POST" onsubmit="return validateAddQuestion()">
          <input type="hidden" name="action" value="addQuestion">
          <input type="hidden" name="examId" value="<%= examId %>">
          <div class="form-group">
            <label>Question Text *</label>
            <textarea id="questionText" name="questionText" rows="3" placeholder="Enter your MCQ question..." required></textarea>
          </div>
          <div class="form-group">
            <label>Option A *</label>
            <input type="text" id="optionA" name="optionA" placeholder="Option A" required>
          </div>
          <div class="form-group">
            <label>Option B *</label>
            <input type="text" id="optionB" name="optionB" placeholder="Option B" required>
          </div>
          <div class="form-group">
            <label>Option C *</label>
            <input type="text" id="optionC" name="optionC" placeholder="Option C" required>
          </div>
          <div class="form-group">
            <label>Option D *</label>
            <input type="text" id="optionD" name="optionD" placeholder="Option D" required>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Correct Answer *</label>
              <select id="correctAnswer" name="correctAnswer" required>
                <option value="">Select</option>
                <option value="A">A</option><option value="B">B</option>
                <option value="C">C</option><option value="D">D</option>
              </select>
            </div>
            <div class="form-group">
              <label>Difficulty *</label>
              <select name="difficulty" required>
                <option value="Easy">Easy</option>
                <option value="Medium" selected>Medium</option>
                <option value="Hard">Hard</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>Topic / Category</label>
            <input type="text" name="topic" placeholder="e.g. Arrays, Sorting...">
          </div>
          <button type="submit" class="btn btn-amber btn-full">Add Question</button>
        </form>
      </div>
    </div>

    <!-- Questions List -->
    <div class="card">
      <div class="card-header"><h3>Questions (<%= questions.size() %>)</h3></div>
      <div style="max-height:80vh;overflow-y:auto">
        <% if (questions.isEmpty()) { %>
        <div class="empty-state" style="padding:60px">
          <div class="empty-state-icon"><i data-lucide="circle-help" style="width:48px;height:48px"></i></div>
          <h3>No questions yet</h3>
          <p>Add questions using the form on the left.</p>
        </div>
        <% } %>
        <% int qi = 1; for (Question q : questions) {
            String bCls = "Easy".equals(q.getDifficulty()) ? "badge-easy" : "Hard".equals(q.getDifficulty()) ? "badge-hard" : "badge-medium"; %>
        <div style="padding:18px 20px;border-bottom:1px solid #f1f5f9">
          <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px">
            <div style="flex:1">
              <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
                <span style="font-weight:800;color:#94a3b8;font-size:0.8rem">Q<%= qi++ %></span>
                <span class="badge <%= bCls %>"><%= q.getDifficulty() %></span>
                <% if (q.getTopic() != null && !q.getTopic().isEmpty()) { %>
                <span class="badge badge-navy"><%= q.getTopic() %></span>
                <% } %>
              </div>
              <p style="font-weight:600;color:#0f172a;margin-bottom:10px;line-height:1.5"><%= q.getQuestionText() %></p>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:4px 16px;font-size:0.82rem">
                <span style="color:<%= 'A'==q.getCorrectAnswer()?"#065f46":"#64748b" %>"><strong>A.</strong> <%= q.getOptionA() %></span>
                <span style="color:<%= 'B'==q.getCorrectAnswer()?"#065f46":"#64748b" %>"><strong>B.</strong> <%= q.getOptionB() %></span>
                <span style="color:<%= 'C'==q.getCorrectAnswer()?"#065f46":"#64748b" %>"><strong>C.</strong> <%= q.getOptionC() %></span>
                <span style="color:<%= 'D'==q.getCorrectAnswer()?"#065f46":"#64748b" %>"><strong>D.</strong> <%= q.getOptionD() %></span>
              </div>
              <div style="margin-top:8px;font-size:0.8rem">
                <i data-lucide="circle-check" style="width:14px;height:14px;vertical-align:-2px;color:#065f46"></i> Correct Answer: <strong style="color:#065f46"><%= q.getCorrectAnswer() %></strong>
              </div>
            </div>
            <form id="qdel-<%= q.getId() %>" action="<%= request.getContextPath() %>/teacher" method="POST" style="margin:0;flex-shrink:0">
              <input type="hidden" name="action" value="deleteQuestion">
              <input type="hidden" name="qId" value="<%= q.getId() %>">
              <input type="hidden" name="examId" value="<%= examId %>">
              <button type="button" class="btn btn-danger btn-sm"
                onclick="confirmDelete('qdel-<%= q.getId() %>','Delete this question?')">Delete</button>
            </form>
          </div>
        </div>
        <% } %>
      </div>
    </div>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>lucide.createIcons();</script>
</body>
</html>
