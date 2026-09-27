<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Error — AdaptExam</title>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;800&display=swap" rel="stylesheet">
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Plus Jakarta Sans',sans-serif;background:#0d1428;min-height:100vh;display:flex;align-items:center;justify-content:center;color:white}
    .box{text-align:center;padding:60px 40px;max-width:480px}
    .code{font-size:6rem;font-weight:800;color:#f59e0b;line-height:1}
    h1{font-size:1.6rem;margin:16px 0 10px}
    p{color:#94a3b8;margin-bottom:28px}
    a{display:inline-block;padding:11px 24px;background:#1e3a72;color:white;border-radius:8px;text-decoration:none;font-weight:600}
    a:hover{background:#f59e0b;color:#0d1428}
  </style>
</head>
<body>
  <div class="box">
    <div class="code"><%= request.getAttribute("javax.servlet.error.status_code") != null ? request.getAttribute("javax.servlet.error.status_code") : "Error" %></div>
    <h1>Something went wrong</h1>
    <p>The page you're looking for doesn't exist or an error occurred.</p>
    <a href="<%= request.getContextPath() %>/jsp/login.jsp"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:-3px"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg> Go Home</a>
  </div>
</body>
</html>
