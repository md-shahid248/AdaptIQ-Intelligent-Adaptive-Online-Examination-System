<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.adaptiveexam.dao.*, com.adaptiveexam.models.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Admin".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    List<Subject> subjects = new SubjectDAO().getAllSubjects();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Manage Subjects — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header"><div><h1>Manage Subjects</h1><p>Create and manage exam subjects</p></div></div>

  <div style="display:grid;grid-template-columns:340px 1fr;gap:24px;align-items:start">
    <div class="card">
      <div class="card-header"><h3>Add Subject</h3></div>
      <div class="card-body">
        <form action="<%= request.getContextPath() %>/admin" method="POST">
          <input type="hidden" name="action" value="addSubject">
          <div class="form-group">
            <label>Subject Name</label>
            <input type="text" name="name" placeholder="e.g. Data Structures" required>
          </div>
          <div class="form-group">
            <label>Description</label>
            <textarea name="description" placeholder="Brief description..."></textarea>
          </div>
          <button type="submit" class="btn btn-amber btn-full">Add Subject</button>
        </form>
      </div>
    </div>

    <div class="card">
      <div class="card-header"><h3>All Subjects (<%= subjects.size() %>)</h3></div>
      <div class="table-wrap" style="border:none">
        <table>
          <thead><tr><th>#</th><th>Subject Name</th><th>Description</th><th>Action</th></tr></thead>
          <tbody>
            <% if (subjects.isEmpty()) { %>
            <tr><td colspan="4"><div class="empty-state" style="padding:40px"><div class="empty-state-icon"><i data-lucide="book-open" style="width:48px;height:48px"></i></div><h3>No subjects yet</h3></div></td></tr>
            <% } %>
            <% int si=1; for (Subject s : subjects) { %>
            <tr>
              <td style="color:#94a3b8"><%= si++ %></td>
              <td><strong><%= s.getName() %></strong></td>
              <td style="color:#64748b;font-size:0.875rem"><%= s.getDescription() != null ? s.getDescription() : "—" %></td>
              <td>
                <form id="sdel-<%= s.getId() %>" action="<%= request.getContextPath() %>/admin" method="POST" style="margin:0">
                  <input type="hidden" name="action" value="deleteSubject">
                  <input type="hidden" name="id" value="<%= s.getId() %>">
                  <button type="button" class="btn btn-danger btn-sm"
                    onclick="confirmDelete('sdel-<%= s.getId() %>', 'Delete subject <%= s.getName() %>? All related exams will be deleted.')">
                    Delete
                  </button>
                </form>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
<script src="<%= request.getContextPath() %>/js/app.js"></script>
<script>lucide.createIcons();</script>
</body>
</html>
