B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Admin Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Model As Map
End Sub

Public Sub Initialize
	Model.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	HRM.Initialize
	'ShowDashboardPage
	
	Select Main.AUTHENTICATION_TYPE.ToUpperCase
		Case "JSON WEB TOKEN AUTHENTICATION"
			If Request.RequestURI.EqualsIgnoreCase("/dashboard") Then
				If Request.GetSession.GetAttribute2(Main.PREFIX & "authenticated", False) Then
					ShowDashboardPage
					Return
				End If
			Else If Request.RequestURI.EqualsIgnoreCase("/starter") Then
				ShowStarterPage
				Return
			Else If Request.RequestURI.EqualsIgnoreCase("/login") Then
				ShowLoginPage
				Return
			End If
			Utility.ReturnLocation(Main.API_PATH & "login", Response)
		Case Else
			If Request.RequestURI.EqualsIgnoreCase("/dashboard") Then
				If Request.GetSession.GetAttribute2(Main.PREFIX & "authenticated", False) Then
					ShowDashboardPage
					Return
				End If
			Else If Request.RequestURI.EqualsIgnoreCase("/starter") Then
				ShowStarterPage
				Return
			Else If Request.RequestURI.EqualsIgnoreCase("/login") Then
				ShowLoginPage
				Return
			End If
			Utility.ReturnLocation(Main.API_PATH & "login", Response)
	End Select
End Sub

Private Sub ShowLoginPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("login.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	'strMain = Utility.BuildScript(strMain, "")
	Utility.ReturnHtml(strMain, Response)
End Sub

' Download Admin dashboard template
' https://github.com/colorlibhq/AdminLTE
Private Sub ShowDashboardPage
	Dim strMain As String = Utility.ReadTextFile("index3.html")
	If Main.SESSION_ENABLED Then
		Dim user_name As String = Request.GetSession.GetAttribute2(Main.PREFIX & "username", "")
		Model.Put("user_name", Utility.DecodeURL(user_name))
		strMain = Utility.BuildHtml(strMain, Model)
	End If
	Utility.ReturnHtml(strMain, Response)
End Sub

Private Sub ShowStarterPage
	Dim strMain As String = Utility.ReadTextFile("starter.html")
	If Main.SESSION_ENABLED Then
		Dim user_name As String = Request.GetSession.GetAttribute2(Main.PREFIX & "username", "")
		Model.Put("user_name", Utility.DecodeURL(user_name))
		strMain = Utility.BuildHtml(strMain, Model)
	End If
	Utility.ReturnHtml(strMain, Response)
End Sub