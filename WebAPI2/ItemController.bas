B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Server Controller
' Version 1.01
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Elements() As String
	Private Method As String
	Private Version As String
	Private ApiVersionIndex As Int
	Private ControllerIndex As Int
	Private ElementLastIndex As Int
	Private FirstIndex As Int
	Private SecondIndex As Int
End Sub

' Initialize Controller object
' Call Route after Initialize
' <code>Item.Route</code>
' Remember to add the following code to show in Help
' <code>Controllers.Add("ItemController")</code>
Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

' Main Router
Public Sub Route
	Method = Request.Method.ToUpperCase
	Elements = Utility.GetUriElements(Request.RequestURI)
	ElementLastIndex = Elements.Length - 1
	ApiVersionIndex = Main.Element.ApiVersionIndex
	ControllerIndex = Main.Element.ApiControllerIndex
	If ElementLastIndex > ControllerIndex Then FirstIndex = ControllerIndex + 1
	If ElementLastIndex > ControllerIndex + 1 Then SecondIndex = ControllerIndex + 2
	Version = Elements(ApiVersionIndex)
	
	Select Method
		Case "GET"
			RouteGet
		Case "POST"
			RoutePost
		Case "PUT"
			RoutePut
		Case "DELETE"
			RouteDelete
		Case Else
			Log("Unsupported method: " & Method)
			Utility.ReturnMethodNotAllow(Response)
	End Select
End Sub

' Router for GET request
Private Sub RouteGet
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					GetItem
					Return
				Case FirstIndex
					Dim FirstElement As String = Elements(FirstIndex)
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					GetOneItem(FirstElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for POST request
Private Sub RoutePost
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					PostItem
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for PUT request
Private Sub RoutePut
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					Dim FirstElement As String = Elements(FirstIndex)
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					PutItem(FirstElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Router for DELETE request
Private Sub RouteDelete
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					Dim FirstElement As String = Elements(FirstIndex)
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					DeleteItem(FirstElement)
					Return
				Case SecondIndex
					Dim FirstElement As String = Elements(FirstIndex)
					Dim SecondElement As String = Elements(SecondIndex)
					If Utility.CheckInteger(FirstElement) = False Then
						Utility.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					DeleteItemKey(FirstElement, SecondElement)
					Return
			End Select
	End Select
	Utility.ReturnBadRequest(Response)
End Sub

Private Sub GetItem
	' #Version = v2
	' #Desc = Read all Items in MimimaList
	HRM.ResponseData = Main.MinimaItem.List
	HRM.ResponseCode = 200
	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(HRM, "List", Response)
	Else
		Utility.ReturnHttpResponse(HRM, Response)
	End If
End Sub

Private Sub GetOneItem (id As Long)
	' #Version = v2
	' #Desc = Read one Item in MinimaList
	' #Elements = [":index"]
	Dim M1 As Map = CreateMap()
	If id < 1 Then
		HRM.ResponseError = "Invalid id Value"
		HRM.ResponseCode = 404
	Else
		M1 = Main.MinimaItem.Find(id)
		HRM.ResponseCode = 200
	End If
	
	If Main.SimpleResponse Then
		HRM.ResponseObject = M1
		Utility.ReturnSimpleHttpResponse(HRM, "Map", Response)
	Else
		HRM.ResponseData.Initialize
		HRM.ResponseData.Add(M1)
		Utility.ReturnHttpResponse(HRM, Response)
	End If
End Sub

Private Sub PostItem
	' #Version = v2
	' #Desc = Add a new Item to MinimaList
	' #Body = {<br>&nbsp; "model": "item",<br>&nbsp; "key1": "value1",<br>&nbsp; "key2": "value2"<br>}
	Dim M1 As Map = CreateMap()
	Dim data As Map = Utility.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseError = "Invalid Map Object"
		HRM.ResponseCode = 400
	Else If data.ContainsKey("") Then
		HRM.ResponseError = "Invalid Key Value"
		HRM.ResponseCode = 400
	Else
		Main.MinimaItem.Add(data)
		M1 = Main.MinimaItem.Last
		HRM.ResponseCode = 200
	End If
	
	If Main.SimpleResponse Then
		HRM.ResponseObject = M1
		Utility.ReturnSimpleHttpResponse(HRM, "Map", Response)
	Else
		HRM.ResponseData.Initialize
		HRM.ResponseData.Add(M1)
		Utility.ReturnHttpResponse(HRM, Response)
	End If
	If Main.KVS_ENABLED Then WriteKVS
End Sub

Private Sub PutItem (id As Long)
	' #Version = v2
	' #Desc = Update (Patch) full or partial data of Item in MinimaList
	' #Body = {<br>&nbsp; "key": value<br>}
	' #Elements = [":index"]
	Dim M1 As Map = CreateMap()
	Dim data As Map = Utility.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseError = "Invalid Map Object"
		HRM.ResponseCode = 404
	Else
		If id < 1 Then
			HRM.ResponseError = "Invalid id Value"
			HRM.ResponseCode = 404
		Else If data.ContainsKey("") Then
			HRM.ResponseError = "Invalid Key Value"
			HRM.ResponseCode = 400
		Else
			M1 = Main.MinimaItem.Find(id)
			For Each Key As String In data.Keys
				M1.Put(Key, data.Get(Key))
			Next
			HRM.ResponseCode = 200
		End If
	End If
	
	If Main.SimpleResponse Then
		HRM.ResponseObject = M1
		Utility.ReturnSimpleHttpResponse(HRM, "Map", Response)
	Else
		HRM.ResponseData.Initialize
		HRM.ResponseData.Add(M1)
		Utility.ReturnHttpResponse(HRM, Response)
	End If
	If Main.KVS_ENABLED Then WriteKVS
End Sub

Private Sub DeleteItem (id As Long)
	' #Version = v2
	' #Desc = Delete Item in MinimaList
	' #Elements = [":id"]
	Dim L As List
	L.Initialize
	If id < 1 Then
		HRM.ResponseError = "Invalid id Value"
		HRM.ResponseCode = 404
	Else
		Dim Index As Int = Main.MinimaItem.IndexFromId(id)
		Main.MinimaItem.List.RemoveAt(Index)
		HRM.ResponseCode = 200
	End If
	
	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(HRM, "List", Response)
	Else
		Utility.ReturnHttpResponse(HRM, Response)
	End If
	If Main.KVS_ENABLED Then WriteKVS
End Sub

Private Sub DeleteItemKey (id As Long, Key As String)
	' #Version = v2
	' #Desc = Delete key of Item in MinimaList
	' #Elements = [":id", ":key"]
	Dim L As List
	L.Initialize
	If id < 1 Then
		HRM.ResponseError = "Invalid id Value"
		HRM.ResponseCode = 404
	Else
		Dim Index As Int = Main.MinimaItem.IndexFromId(id)
		If Main.MinimaItem.List.Get(Index).As(Map).ContainsKey(Key) Then
			Main.MinimaItem.RemoveKey(Key, Index)
			HRM.ResponseCode = 200
		Else
			HRM.ResponseError = "Invalid Key Value"
			HRM.ResponseCode = 404
		End If
	End If

	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(HRM, "List", Response)
	Else
		Utility.ReturnHttpResponse(HRM, Response)
	End If
	If Main.KVS_ENABLED Then WriteKVS
End Sub

Private Sub WriteKVS
	Main.KVS.Put("ItemFirst", Main.MinimaItem.First)
	Main.KVS.Put("ItemLast", Main.MinimaItem.Last)
	Main.KVS.Put("ItemList", Main.MinimaItem.List)
End Sub