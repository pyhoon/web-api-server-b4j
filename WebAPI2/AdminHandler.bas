B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Admin Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	'Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	If req.GetSession.GetAttribute2("logged in", False) = True Then
		'Response.Write("Logged In")
		ShowDashboardPage
	Else
		'Response.Write("Please Log In")
		If Request.RequestURI.EqualsIgnoreCase("/dashboard") Then
			ShowDashboardPage
		Else If Request.RequestURI.EqualsIgnoreCase("/starter") Then
			ShowStarterdPage
		Else
			ShowLoginPage
		End If
	End If
End Sub

Private Sub ShowLoginPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("login.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapisearch.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	Utility.ReturnHTML(strMain, Response)
End Sub

' Download Admin dashboard template
' https://github.com/colorlibhq/AdminLTE
Private Sub ShowDashboardPage
	Dim strMain As String = Utility.ReadTextFile("index3.html")
	Utility.ReturnHTML(strMain, Response)
End Sub

Private Sub ShowStarterdPage
	Dim strMain As String = Utility.ReadTextFile("starter.html")
	Utility.ReturnHTML(strMain, Response)
End Sub