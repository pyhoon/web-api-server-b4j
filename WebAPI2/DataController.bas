B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Data Controller class
' Version 2.02
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Public Sub GetData
	' #Version = v2
	' #Desc = Read all Items in MimimaList
	HRM.ResponseData = Main.Minima.List
	HRM.ResponseCode = 200
	If Main.SimpleResponse Then
		'Response.Write(Main.Model.As(JSON).ToString)
		Utility.ReturnSimpleHttpResponse(HRM, "List", Response)
	Else
		Utility.ReturnHttpResponse(HRM, Response)
	End If
End Sub

Public Sub GetOneData (Index As Long)
	' #Version = v2
	' #Desc = Read one Item in MinimaList
	' #Elements = [":index"]
	Dim M1 As Map = CreateMap()
	If Index > Main.Minima.List.Size - 1 Then
		HRM.ResponseError = "Invalid Index Value"
		HRM.ResponseCode = 404
	Else
		M1 = Main.Minima.List.Get(Index)
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

Public Sub PostData
	' #Version = v2
	' #Desc = Add a new Item to MinimaList
	' #Body = {<br>&nbsp; "key1": "value1",<br>&nbsp; "key2": "value2"<br>}
	Dim M1 As Map = CreateMap()
	Dim data As Map = Utility.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseError = "Invalid Map Object"
		HRM.ResponseCode = 400
	Else If data.ContainsKey("") Then
		HRM.ResponseError = "Invalid Key Value"
		HRM.ResponseCode = 400
	Else
		Main.Minima.Add(data)
		M1 = Main.Minima.Last
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

Public Sub PutData (Index As Long)
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
		If Index > Main.Minima.List.Size - 1 Then
			HRM.ResponseError = "Invalid Index Value"
			HRM.ResponseCode = 404
		Else If data.ContainsKey("") Then
			HRM.ResponseError = "Invalid Key Value"
			HRM.ResponseCode = 400
		Else
			'Dim M1 As Map = Main.Minima.Find(id)
			M1 = Main.Minima.List.Get(Index)
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

Public Sub DeleteData (Index As Long)
	' #Version = v2
	' #Desc = Delete Item in MinimaList
	' #Elements = [":index"]
	Dim L As List
	L.Initialize
	If Index > Main.Minima.List.Size - 1 Then
		HRM.ResponseError = "Invalid Index Value"
		HRM.ResponseCode = 404
	Else
		'Index = Main.Minima.IndexFromId(id)
		Main.Minima.List.RemoveAt(Index)
		HRM.ResponseCode = 200
	End If
	
	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(HRM, "List", Response)
	Else
		Utility.ReturnHttpResponse(HRM, Response)
	End If
	If Main.KVS_ENABLED Then WriteKVS
End Sub

Public Sub DeleteDataKey (Index As Long, Key As String)
	' #Version = v2
	' #Desc = Delete key of Item in MinimaList
	' #Elements = [":index", ":key"]
	Dim L As List
	L.Initialize
	If Index > Main.Minima.List.Size - 1 Then
		HRM.ResponseError = "Invalid Index Value"
		HRM.ResponseCode = 404
	Else
		'Index = Main.Minima.IndexFromId(id)
		If Main.Minima.List.Get(Index).As(Map).ContainsKey(Key) Then
			Main.Minima.RemoveKey(Key, Index)
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
	Main.KVS.Put("First", Main.Minima.First)
	Main.KVS.Put("Last", Main.Minima.Last)
	Main.KVS.Put("List", Main.Minima.List)
End Sub