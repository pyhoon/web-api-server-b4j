B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Web Handler class
' Version 2.02
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Elements() As String
	Private Method As String
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Method = Request.Method.ToUpperCase
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ProcessRequest
	Log(Request.RequestURI)
	Elements = Utility.GetUriElements(Request.RequestURI)
	
	' Handle /web/
	If ElementLastIndex < Main.Element.WebControllerIndex Then
		Select Method
			Case "GET"
				Dim WelcomePage As IndexController
				WelcomePage.Initialize(Request, Response)
				WelcomePage.Show
				Return
		End Select
	End If
	
	Utility.ReturnHtmlPageNotFound(Response)
End Sub