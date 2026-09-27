<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
  Entry-point stub: redirects to the login page and renders nothing.
  The HTML shell that used to wrap this scriptlet was dead markup —
  sendRedirect() commits the response, so nothing after it was ever sent.

  The redirect target is left exactly as-is (rule: don't change URLs/routes).
  Note for review: this path is relative, so from /jsp/index.jsp it resolves
  to /jsp/jsp/login.jsp. web.xml's welcome-file (jsp/login.jsp) is what
  actually serves the site root, so this file appears to be unused Eclipse
  scaffolding. Flagged, not changed.
--%>
<%
    response.sendRedirect("jsp/login.jsp");
%>
