<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.adaptiveexam.dao.*, com.adaptiveexam.models.*" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"Admin".equals(currentUser.getRole())) {
        response.sendRedirect(request.getContextPath() + "/jsp/login.jsp"); return;
    }
    List<User> allUsers = new UserDAO().getAllUsers();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<%
    request.setAttribute("pageTitle", "Manage Users — AdaptExam");
    request.setAttribute("useLucide", Boolean.TRUE);
%>
<%@ include file="../common/head.jsp" %>
</head>
<body>
<%@ include file="../common/navbar.jsp" %>
<div class="page-container">
  <div class="page-header">
    <div><h1>Manage Users</h1><p>Add, view, and remove system users</p></div>
  </div>

  <div style="display:grid;grid-template-columns:340px 1fr;gap:24px;align-items:start">
    <!-- Add User Form -->
    <div class="card">
      <div class="card-header"><h3>Add New User</h3></div>
      <div class="card-body">
        <form action="<%= request.getContextPath() %>/admin" method="POST" onsubmit="return validateAddUser()">
          <input type="hidden" name="action" value="addUser">
          <div class="form-group">
            <label>Full Name</label>
            <input type="text" id="name" name="name" placeholder="John Doe" required>
          </div>
          <div class="form-group">
            <label>Email Address</label>
            <input type="email" id="email" name="email" placeholder="john@example.com" required>
          </div>
          <div class="form-group">
            <label>Password</label>
            <input type="password" id="password" name="password" placeholder="Min 6 characters" required>
          </div>
          <div class="form-group">
            <label>Role</label>
            <select id="role" name="role" required>
              <option value="">Select Role</option>
              <option value="Student">Student</option>
              <option value="Teacher">Teacher</option>
              <option value="Admin">Admin</option>
            </select>
          </div>
          <button type="submit" class="btn btn-amber btn-full">Add User</button>
        </form>
      </div>
    </div>

    <!-- Users Table -->
    <div class="card">
      <div class="card-header">
        <h3>All Users (<%= allUsers.size() %>)</h3>
      </div>
      <div class="table-wrap" style="border:none">
        <table>
          <thead>
            <tr><th>Name</th><th>Email</th><th>Role</th><th>Joined</th><th>Action</th></tr>
          </thead>
          <tbody>
            <% if (allUsers.isEmpty()) { %>
            <tr><td colspan="5"><div class="empty-state" style="padding:40px">No users found.</div></td></tr>
            <% } %>
            <% for (User u : allUsers) {
                String roleClass = "Admin".equals(u.getRole()) ? "badge-hard" :
                                   "Teacher".equals(u.getRole()) ? "badge-medium" : "badge-easy";
            %>
            <tr>
              <td>
                <div style="display:flex;align-items:center;gap:10px">
                  <div class="avatar-circle" style="width:32px;height:32px;font-size:0.8rem">
                    <%= u.getName().length()>=2 ? u.getName().substring(0,2).toUpperCase() : u.getName().toUpperCase() %>
                  </div>
                  <strong><%= u.getName() %></strong>
                </div>
              </td>
              <td style="color:#64748b;font-size:0.85rem"><%= u.getEmail() %></td>
              <td><span class="badge <%= roleClass %>"><%= u.getRole() %></span></td>
              <td style="color:#94a3b8;font-size:0.82rem"><%= u.getCreatedAt() != null ? u.getCreatedAt().toString().substring(0,10) : "—" %></td>
              <td>
                <% if (u.getId() != currentUser.getId()) { %>
                <form id="del-<%= u.getId() %>" action="<%= request.getContextPath() %>/admin" method="POST" style="margin:0">
                  <input type="hidden" name="action" value="deleteUser">
                  <input type="hidden" name="id" value="<%= u.getId() %>">
                  <button type="button" class="btn btn-danger btn-sm"
                    onclick="confirmDelete('del-<%= u.getId() %>', 'Delete user <%= u.getName() %>? This cannot be undone.')">
                    Delete
                  </button>
                </form>
                <% } else { %>
                <span style="color:#94a3b8;font-size:0.82rem;font-style:italic">You</span>
                <% } %>
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
