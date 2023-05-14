B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Handler class
' Version 2.01
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

	Dim ApiVersionIndex As Int = Main.Element.ApiVersionIndex
	Dim ControllerIndex As Int = Main.Element.ApiControllerIndex
	Dim ApiVersionElement As String = Elements(ApiVersionIndex)
	Dim ControllerElement As String = Elements(ControllerIndex)
	If ElementLastIndex > Main.Element.ApiControllerIndex Then
		Dim FirstIndex As Int = Main.Element.ApiControllerIndex + 1
		If ElementLastIndex > Main.Element.ApiControllerIndex + 1 Then
			Dim SecondIndex As Int = Main.Element.ApiControllerIndex + 2
		End If
	End If
	
	Select ControllerElement
		Case "data"
			RouteData(ApiVersionElement, ControllerIndex, FirstIndex, SecondIndex)
		Case Else
			Log("Unknown controller: " & ControllerElement)
			Utility.ReturnBadRequest(Response)
	End Select
End Sub

' Main Router for DataController
Private Sub RouteData (Version As String, ControllerIndex As Int, FirstIndex As Int, SecondIndex As Int)
	Dim Data As DataController
	Data.Initialize(Request, Response)
	Select Method
		Case "GET"
			RouteDataGet(Version, ControllerIndex, FirstIndex)
		Case "POST"
			RouteDataPost(Version, ControllerIndex)
		Case "PUT"
			RouteDataPut(Version, FirstIndex)
		Case "DELETE"
			RouteDataDelete(Version, FirstIndex, SecondIndex)
		Case Else
			Log("Unsupported method: " & Method)
			Utility.ReturnMethodNotAllow(Response)
	End Select
End Sub

' Router for DataController GET request
Private Sub RouteDataGet (Version As String, ControllerIndex As Int, FirstIndex As Int)
	Dim Data As DataController
	Data.Initialize(Request, Response)
	Select ElementLastIndex
		Case ControllerIndex
			Select Version
				Case "v2"
					Data.GetData
					Return
			End Select
		Case FirstIndex
			Select Version
				Case "v2"
					Dim FirstElement As String = Elements(FirstIndex)
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					Data.GetOneData(FirstElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for DataController POST request
Private Sub RouteDataPost (Version As String, ControllerIndex As Int)
	Dim Data As DataController
	Data.Initialize(Request, Response)
	Select ElementLastIndex
		Case ControllerIndex
			Select Version
				Case "v2"
					Data.PostData
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for DataController PUT request
Private Sub RouteDataPut (Version As String, FirstIndex As Int)
	Dim Data As DataController
	Data.Initialize(Request, Response)
	Dim FirstElement As String = Elements(FirstIndex)
	Select ElementLastIndex
		Case FirstIndex
			Select Version
				Case "v2"
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					Data.PutData(FirstElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for DataController DELETE request
Private Sub RouteDataDelete (Version As String, FirstIndex As Int, SecondIndex As Int)
	Dim Data As DataController
	Data.Initialize(Request, Response)
	Dim FirstElement As String = Elements(FirstIndex)
	Dim SecondElement As String = Elements(SecondIndex)
	Select ElementLastIndex
		Case FirstIndex
			Select Version
				Case "v2"
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					Data.DeleteData(FirstElement)
					Return
			End Select
		Case SecondIndex
			Select Version
				Case "v2"
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If					
					Data.DeleteDataKey(FirstElement, SecondElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub