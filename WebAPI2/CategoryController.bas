B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Controller
' Version 1.03
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Method As String
	Private Version As String
	Private Elements() As String
	Private ApiVersionIndex As Int
	Private ControllerIndex As Int
	Private ElementLastIndex As Int
	Private FirstIndex As Int
	Private FirstElement As String
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Private Sub ReturnApiResponse
	HRM.SimpleResponse.Simple = Main.SimpleResponse
	HRM.SimpleResponse.Format = Main.SimpleResponseFormat
	HRM.SimpleResponse.DataKey = Main.SimpleResponseDataKey
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

' API Router
Public Sub RouteApi
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ElementLastIndex = Elements.Length - 1
	ApiVersionIndex = Main.Element.ApiVersionIndex
	Version = Elements(ApiVersionIndex)
	ControllerIndex = Main.Element.ApiControllerIndex
	If ElementLastIndex > ControllerIndex Then
		FirstIndex = ControllerIndex + 1
		FirstElement = Elements(FirstIndex)
	End If

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
			WebApiUtils.ReturnMethodNotAllow(Response)
	End Select
End Sub

' Web Router
Public Sub RouteWeb
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ElementLastIndex = Elements.Length - 1
	ControllerIndex = Main.Element.WebControllerIndex
	If ElementLastIndex > ControllerIndex Then
		FirstIndex = ControllerIndex + 1
		FirstElement = Elements(FirstIndex)
	End If
	
	Select Method
		Case "GET"
			Select ElementLastIndex
				Case ControllerIndex
					ShowPage
					Return
			End Select
		Case Else
			Log("Unsupported method: " & Method)
			WebApiUtils.ReturnMethodNotAllow(Response)
	End Select
End Sub

' Router for GET request
Private Sub RouteGet
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					GetCategories
					Return
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					GetCategory(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for POST request
Private Sub RoutePost
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					PostCategory
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for PUT request
Private Sub RoutePut
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					PutCategory(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

' Router for DELETE request
Private Sub RouteDelete
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					DeleteCategory(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub GetCategories
	' #Plural = Categories
	' #Version = v2
	' #Desc = Read all Categories
	
	#If MinimaList
	HRM.ResponseCode = 200
	HRM.ResponseData = Main.CategoryList.List
	ReturnApiResponse
	#End If

	#If Not(MinimaList) And Not(No_Database)
	Dim list As List
	list.Initialize
	
	Dim con As SQL = Main.DBConnector.DBOpen
	Dim qry As String = "SELECT * FROM tbl_category"
	Dim rs As ResultSet = con.ExecQuery(qry)
	Do While rs.NextRow
		Dim map As Map
		map.Initialize
		For i = 0 To rs.ColumnCount - 1
			Select rs.GetColumnName(i)
				Case "id"
					map.Put(rs.GetColumnName(i), rs.GetInt2(i))
				Case Else
					map.Put(rs.GetColumnName(i), rs.GetString2(i))
			End Select
		Next
		list.Add(map)
	Loop
	rs.Close
	
	HRM.ResponseCode = 200
	HRM.ResponseData = list
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

Private Sub GetCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Read one Category by id
	' #Elements = [":id"]
	
	#If MinimaList
	Dim M1 As Map = Main.CategoryList.Find(id)
	If M1.Size > 0 Then
		HRM.ResponseCode = 200
	Else
		HRM.ResponseCode = 404
	End If
	HRM.ResponseObject = M1
	ReturnApiResponse
	#End If

	#If Not(MinimaList) And Not(No_Database)
	Dim map As Map
	map.Initialize
	Dim con As SQL = Main.DBConnector.DBOpen
	Dim qry As String = "SELECT * FROM tbl_category WHERE id = ?"
	Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(id))
	Do While rs.NextRow
		For i = 0 To rs.ColumnCount - 1
			Select rs.GetColumnName(i)
				Case "id"
					map.Put(rs.GetColumnName(i), rs.GetInt2(i))
				Case Else
					map.Put(rs.GetColumnName(i), rs.GetString2(i))
			End Select
		Next
	Loop
	rs.Close
	
	HRM.ResponseCode = 200
	HRM.ResponseObject = map
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

Private Sub PostCategory
	' #Plural = Categories
	' #Version = v2
	' #Desc = Add a new Category
	' #Body = {<br>&nbsp;"name": "category_name"<br>}
	
	#If MinimaList
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
	Else If data.ContainsKey("") Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid key value"
	Else
	' Make it compatible with Web API Client v1
		If data.ContainsKey("name") Then
			data.Put("category_name", data.Get("name"))
			data.Remove("name")
		End If
		If Main.CategoryList.FindAll(Array("category_name"), Array(data.Get("category_name"))).Size > 0 Then
			HRM.ResponseCode = 409
			HRM.ResponseError = "Category Name already exist"
			ReturnApiResponse
			Return
		End If
		
		If Not(data.ContainsKey("created_date")) Then
			data.Put("created_date", WebApiUtils.CurrentDateTime)
		End If
		Main.CategoryList.Add(data)
		HRM.ResponseCode = 201
		HRM.ResponseMessage = "Category Created"
		HRM.ResponseObject = Main.CategoryList.Last
		If Main.KVS_ENABLED Then Main.WriteKVS("CategoryList", Main.CategoryList)
	End If
	ReturnApiResponse
	#End If
	
	#If Not(MinimaList) And Not(No_Database)
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
	Else If data.ContainsKey("") Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid key value"
	Else
		' Make it compatible with Web API Client v1
		If data.ContainsKey("name") Then
			data.Put("category_name", data.Get("name"))
			data.Remove("name")
		End If
		
		Dim found As Boolean
		Dim con As SQL = Main.DBConnector.DBOpen
		Dim qry As String = "SELECT * FROM tbl_category WHERE category_name = ?"
		Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(data.Get("category_name")))
		Do While rs.NextRow
			found = True
		Loop
		rs.Close
		
		If found Then
			HRM.ResponseCode = 409
			HRM.ResponseError = "Category Name already exist"
		Else
			Dim qry As String = "INSERT INTO tbl_category (category_name) VALUES (?)"
			con.BeginTransaction
			con.ExecNonQuery2(qry, Array As String(data.Get("category_name")))
			con.TransactionSuccessful

			#If SQLite
			Dim qry As String = "SELECT LAST_INSERT_ROWID()"
			#Else If MySQL
			Dim qry As String = "SELECT LAST_INSERT_ID()"
			#End If
			Dim newId As Int = con.ExecQuerySingleResult(qry)
			Dim qry As String = "SELECT * FROM tbl_category WHERE id = ?"
			Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(newId))
			Do While rs.NextRow
				Dim map As Map
				map.Initialize
				For i = 0 To rs.ColumnCount - 1
					Select rs.GetColumnName(i)
						Case "id"
							map.Put(rs.GetColumnName(i), rs.GetInt2(i))
						Case Else
							map.Put(rs.GetColumnName(i), rs.GetString2(i))
					End Select
				Next
			Loop
			rs.Close
		
			HRM.ResponseCode = 201
			HRM.ResponseObject = map
			HRM.ResponseMessage = "Category Created"
		End If		
	End If
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

Private Sub PutCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Update Category by id
	' #Body = {<br>&nbsp;"name": "category_name"<br>}
	' #Elements = [":id"]
	
	#If MinimaList
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
	Else
		If data.ContainsKey("") Then
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid key value"
		Else
			Dim M1 As Map = Main.CategoryList.Find(id)
			If M1.Size = 0 Then
				HRM.ResponseCode = 404
				HRM.ResponseError = "Category not found"
			Else
				' Make it compatible with Web API Client v1
				If data.ContainsKey("name") Then
					data.Put("category_name", data.Get("name"))
					data.Remove("name")
				End If
				For Each item As Map In Main.CategoryList.FindAll(Array("category_name"), Array(data.Get("category_name")))
					If id <> item.Get("id") Then
						HRM.ResponseCode = 409
						HRM.ResponseError = "Category Name already exist"
						ReturnApiResponse
						Return
					End If
				Next

				If Not(data.ContainsKey("updated_date")) Then
					data.Put("updated_date", WebApiUtils.CurrentDateTime)
				End If
				For Each Key As String In data.Keys
					M1.Put(Key, data.Get(Key))
				Next
				HRM.ResponseCode = 200
				HRM.ResponseObject = M1
				If Main.KVS_ENABLED Then Main.WriteKVS("CategoryList", Main.CategoryList)
			End If
		End If
	End If
	ReturnApiResponse
	#End If
	
	#If Not(MinimaList) And Not(No_Database)
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		HRM.ResponseObject.Initialize
	Else
		If data.ContainsKey("") Then
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid key value"
			HRM.ResponseObject.Initialize
		Else
			' Make it compatible with Web API Client v1
			If data.ContainsKey("name") Then
				data.Put("category_name", data.Get("name"))
				data.Remove("name")
			End If
			If Not(data.ContainsKey("modified_date")) Then
				data.Put("modified_date", WebApiUtils.CurrentDateTime)
			End If
			
			Dim found As Boolean
			Dim con As SQL = Main.DBConnector.DBOpen
			Dim qry As String = "SELECT * FROM tbl_category WHERE category_name = ? AND id <> ?"
			Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(data.Get("category_name"), id))
			Do While rs.NextRow
				found = True
			Loop
			rs.Close
			
			If found Then
				HRM.ResponseCode = 409
				HRM.ResponseError = "Category Name already exist"
				HRM.ResponseObject.Initialize
			Else
				Dim found As Boolean
				Dim qry As String = "SELECT * FROM tbl_category WHERE id = ?"
				Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(id))
				Do While rs.NextRow
					found = True
				Loop
				rs.Close
				
				If Not(found) Then
					HRM.ResponseCode = 404
					HRM.ResponseError = "Category not found"
					HRM.ResponseObject.Initialize
				Else
					Dim qry As String = "UPDATE tbl_category SET category_name = ?, modified_date = ? WHERE id = ?"
					con.ExecNonQuery2(qry, Array As String(data.Get("category_name"), data.Get("modified_date"), id))
					Dim qry As String = "SELECT * FROM tbl_category WHERE id = ?"
					Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(id))
					Do While rs.NextRow
						Dim map As Map
						map.Initialize
						For i = 0 To rs.ColumnCount - 1
							Select rs.GetColumnName(i)
								Case "id"
									map.Put(rs.GetColumnName(i), rs.GetInt2(i))
								Case Else
									map.Put(rs.GetColumnName(i), rs.GetString2(i))
							End Select
						Next
					Loop
					rs.Close
					
					HRM.ResponseCode = 200
					HRM.ResponseObject = map
				End If
			End If
		End If
	End If
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

Private Sub DeleteCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Delete Category by id
	' #Elements = [":id"]
	
	#If MinimaList
	Dim Index As Int = Main.CategoryList.IndexFromId(id)
	If Index < 0 Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	Else
		'If Index <= Main.CategoryList.List.Size - 1 Then
		Main.CategoryList.Remove(Index)
		HRM.ResponseCode = 200
		If Main.KVS_ENABLED Then Main.WriteKVS("CategoryList", Main.CategoryList)
		'End If
	End If
	ReturnApiResponse
	#End If
	
	#If Not(MinimaList) And Not(No_Database)
	Dim found As Boolean
	Dim con As SQL = Main.DBConnector.DBOpen
	Dim qry As String = "SELECT * FROM tbl_category WHERE id = ?"
	Dim rs As ResultSet = con.ExecQuery2(qry, Array As String(id))
	Do While rs.NextRow
		found = True
	Loop
	rs.Close
	
	If Not(found) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
		HRM.ResponseObject = CreateMap("error": HRM.ResponseError)
	Else
		Dim qry As String = "DELETE FROM tbl_category WHERE id = ?"
		con.ExecNonQuery2(qry, Array As Int(id))
		HRM.ResponseCode = 200
		HRM.ResponseObject = CreateMap("message": "Success")
	End If
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

' Return Web Page
Private Sub ShowPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("category.html")
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildHtml(strMain, Main.config)
	If Main.SimpleResponse Then
		If Main.SimpleResponseFormat = "Map" Then
			Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapicategory-simple-map.js"></script>"$
		Else
			Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapicategory-simple.js"></script>"$
		End If
	Else
		Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapicategory.js"></script>"$
	End If
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub