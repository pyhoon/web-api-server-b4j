B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Handler class
' Version 2.03
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Elements() As String
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ProcessRequest
    #Region Example
	' ============================================================================
	' What is Index and Element? Controller, First, Second and Last?
	' ============================================================================
	' For URL: http://127.0.0.1:8080/web/api/v2/data/:index/:key
	' 					  |      |    |   |	 |   |		|	  |
	'  			 Root URL ┘		 |    |   |	 |   |		|	  |
	'                Server Port ┘    |   |	 |   |		|	  |
	'    					Root Path ┘   |	 |   |		|	  |
	' 							 API Name ┘	 |   |		|	  |
	'                    APIVersionIndex = 3 ┘   |		|	  |
	'						 ControllerIndex = 4 ┘		|	  |
	'									 FirstIndex = 5 ┘	  |
	'							 (last index) SecondIndex = 6 ┘
	'
	' Index is the position of an element inside the URL
	' If Controller is used, at least ControllerIndex has to be used
	' FirstIndex, SecondIndex, etc are optional
	' ElementLastIndex returns the last position of the rightmost element of URL
	' In this template, we only have a single controller name DataController
	' ============================================================================
    #End Region
	Log(Request.RequestURI)
	Elements = Utility.GetUriElements(Request.RequestURI)
	If ElementLastIndex < Main.Element.ApiControllerIndex Then
		Utility.ReturnBadRequest(Response)
		Return
	End If

	Dim ControllerIndex As Int = Main.Element.ApiControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	Select ControllerElement
		Case "data"
			Dim Data As DataController
			Data.Initialize(Request, Response)
			Data.Route
			Return
	End Select
	
	Log("Unknown controller: " & ControllerElement)
	Utility.ReturnBadRequest(Response)
End Sub