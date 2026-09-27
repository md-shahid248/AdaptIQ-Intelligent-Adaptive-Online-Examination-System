<%--
  Shared <head> contents for every content page.

  Usage — set the flags this page needs, then include INSIDE <head>:

      <head>
      <% request.setAttribute("pageTitle", "Manage Users — AdaptExam"); %>
      <%@ include file="../common/head.jsp" %>
      </head>

  Optional request attributes (omit any you don't need):
      pageTitle   text for <title>                  (String,  default "AdaptExam")
      useMono     also load JetBrains Mono          (Boolean, default false)
      useChartJs  load Chart.js 4.4.0               (Boolean, default false)
      useLucide   load Lucide icon script           (Boolean, default false)

  This is a static include, so it shares the including page's variable scope.
  Locals are therefore __-prefixed to stay collision-free, matching navbar.jsp.
  Deliberately carries no page directive: contentType/pageEncoding come from
  the including page.

  Note: jsp/error.jsp intentionally does NOT use this include — it stays
  self-contained so it still renders if style.css itself fails to load.
--%>
<%
    Object  __rawTitle = request.getAttribute("pageTitle");
    String  __title    = __rawTitle != null ? __rawTitle.toString() : "AdaptExam";
    boolean __mono     = Boolean.TRUE.equals(request.getAttribute("useMono"));
    boolean __chart    = Boolean.TRUE.equals(request.getAttribute("useChartJs"));
    boolean __lucide   = Boolean.TRUE.equals(request.getAttribute("useLucide"));
%>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title><%= __title %></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800<%= __mono ? "&family=JetBrains+Mono:wght@500" : "" %>&display=swap">
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
<% if (__chart)  { %><script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script><% } %>
<% if (__lucide) { %><script src="https://unpkg.com/lucide@latest"></script><% } %>
