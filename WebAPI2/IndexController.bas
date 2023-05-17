B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Index Controller class
' Version 2.02
Sub Class_Globals
	Private Request As ServletRequest 'ignore
	Private Response As ServletResponse
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
End Sub

Public Sub Show
	Dim strMain As String = Utility.ReadTextFile("index.html")
	strMain = Utility.BuildHtml(strMain, Main.Config)
	'Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.search.js"></script>"$
	'strMain = Utility.BuildScript(strMain, strScripts)
	Utility.ReturnHtml(strMain, Response)
End Sub