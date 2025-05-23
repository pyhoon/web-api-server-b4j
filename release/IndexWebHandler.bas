﻿B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.2
@EndOfDesignText@
'Web Handler class
'Version 3.50
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Method As String
	Private Elements() As String
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	If Method <> "GET" Then
		WebApiUtils.ReturnHtmlMethodNotAllowed(Response)
		Return
	End If
	If Elements.Length = 0 Then
		ReturnPage
		Return
	End If
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ReturnPage
	Dim strScripts As String
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", ReturnHelpElement)
	strMain = WebApiUtils.BuildHtml(strMain, Main.ctx)
	strScripts = $"<script src="${Main.conf.ServerUrl}/assets/scripts/search.js"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub

Private Sub ReturnHelpElement As String
	If Main.conf.EnableHelp = False Then
		Return ""
	End If
	Return $"${CRLF & TAB & TAB}<li class="nav-item">
${TAB & TAB & TAB}<a class="nav-link mr-3 font-weight-bold text-white" href="${Main.conf.ServerUrl}/help"><i class="fas fa-cog" title="API"></i> API</a>
${TAB & TAB}</li>"$
End Sub