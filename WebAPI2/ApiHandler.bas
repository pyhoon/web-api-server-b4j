B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Handler class
' Version 2.00
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
	Elements = Utility.GetUriElements(Request.RequestURI)
	If ElementLastIndex < Main.Element.ApiControllerIndex Then
		Utility.ReturnBadRequest(Response)
		Return
	End If
	
	' ============================================================================
	' What is Index and Element? Controller, First, Second and Last?
	' ============================================================================
	' For URL: http://192.168.50.42:8080/web/api/v2/data/:index/:key
	' 					     |       |    |   |	 |   |		|	  |
	'  			 	Root URL ┘		 |    |   |	 |   |		|	  |
	'                    Server Port ┘    |   |	 |   |		|	  |
	'    						Root Path ┘   |	 |   |		|	  |
	' 							     API Name ┘	 |   |		|	  |
	'                        APIVersionIndex = 3 ┘   |		|	  |
	'						     ControllerIndex = 4 ┘		|	  |
	'										 FirstIndex = 5 ┘	  |
	'								  LastIndex / SecondIndex = 6 ┘
	'
	' Index is the position of an element inside the URL
	' ElementLastIndex is the last position of the rightmost element of URL
	' In this template, we only have a single controller name DataController
	' ============================================================================
	
	Dim ApiVersionIndex As Int = Main.Element.ApiVersionIndex
	Dim ApiVersionElement As String = Elements(ApiVersionIndex)
	Dim ControllerIndex As Int = Main.Element.ApiControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	If ElementLastIndex > Main.Element.ApiControllerIndex Then
		Dim FirstIndex As Int = Main.Element.ApiControllerIndex + 1
		Dim FirstElement As String = Elements(FirstIndex)
		If ElementLastIndex > Main.Element.ApiControllerIndex + 1 Then
			Dim SecondIndex As Int = Main.Element.ApiControllerIndex + 2
			Dim SecondElement As String = Elements(SecondIndex)
		End If
	End If
	
	Select ControllerElement
		Case "data"
			Dim Data As DataController
			Data.Initialize(Request, Response)
			Select Method
				Case "GET"
					If Main.Element.Api.Versioning Then
						Select ElementLastIndex
							Case ControllerIndex
								Select ApiVersionElement
									Case "v2"
										Data.GetData
										Return
								End Select
							Case FirstIndex
								Select ApiVersionElement
									Case "v2"
										If Utility.CheckInteger(FirstElement) = False Then
											Utility.ReturnErrorUnprocessableEntity(Response)
											Return
										End If
										Data.GetOneData(FirstElement)
										Return
								End Select
						End Select
					End If
				Case "POST"
					If Main.Element.Api.Versioning Then
						Select ElementLastIndex
							Case ControllerIndex
								Select ApiVersionElement
									Case "v2"
										Data.PostData
										Return
								End Select
						End Select
					End If
				Case "PUT"
					If Main.Element.Api.Versioning Then
						Select ElementLastIndex
							Case FirstIndex
								Select ApiVersionElement
									Case "v2"
										If Utility.CheckInteger(FirstElement) = False Then
											Utility.ReturnErrorUnprocessableEntity(Response)
											Return
										End If
										Data.PutData(FirstElement)
										Return
								End Select
						End Select
					End If
				Case "DELETE"
					If Main.Element.Api.Versioning Then
						Select ElementLastIndex
							Case FirstIndex
								Select ApiVersionElement
									Case "v2"
										If Utility.CheckInteger(FirstElement) = False Then
											Utility.ReturnErrorUnprocessableEntity(Response)
											Return
										End If
										Data.DeleteData(FirstElement)
										Return
								End Select
							Case SecondIndex
								Select ApiVersionElement
									Case "v2"
										If Utility.CheckInteger(FirstElement) = False Then
											Utility.ReturnErrorUnprocessableEntity(Response)
											Return
										End If
										Data.DeleteDataKey(SecondElement, FirstElement)
										Return
								End Select
						End Select
					End If
				Case Else
					Log("Unsupported method: " & Method)
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case Else

	End Select
	Utility.ReturnBadRequest(Response)
End Sub