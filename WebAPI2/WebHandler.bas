B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Web Handler class
' Version 2.08
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Elements() As String
	Private const COLOR_RED As Int = -65536
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ReturnHtmlPageNotFound
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(Response)
End Sub

Private Sub ProcessRequest
	If Main.PRINT_FULL_REQUEST_URL Then
		Log($"${Request.Method}: ${Request.FullRequestURI}"$)
	End If
	
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	
	' Handle /web/
	If ElementLastIndex < Main.Element.WebControllerIndex Then
		Select Request.Method.ToUpperCase
			Case "GET"
				Dim IndexPage As IndexController
				IndexPage.Initialize(Request, Response)
				If Request.GetParameter("default") <> "" Then
					IndexPage.GetSearch
					Return
				End If
				IndexPage.Show
				Return
			Case "POST"
				Dim IndexPage As IndexController
				IndexPage.Initialize(Request, Response)
				IndexPage.PostSearch
				Return
		End Select
	End If
	
	Dim ControllerIndex As Int = Main.Element.WebControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	Select ControllerElement
		Case "categories"
			Dim Categories As CategoriesController
			Categories.Initialize(Request, Response)
			Categories.RouteWeb
			Return
	End Select
	
	LogColor("Unknown url: " & Request.FullRequestURI, COLOR_RED)
	If Request.Method.ToUpperCase = "GET" Then
		ReturnHtmlPageNotFound
	Else
		ReturnMethodNotAllow
	End If
End Sub