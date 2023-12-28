B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Controller
' Version 1.04
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
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
	HRM.SimpleResponse = Main.SimpleResponse
	DB.Initialize(OpenDBConnection, DBEngine)
	DB.UseTimestamps = True
End Sub

Private Sub DBEngine As String
	Return Main.DBConnector.DBEngine
End Sub

Private Sub OpenDBConnection As SQL
	Return Main.DBConnector.DBOpen
End Sub

Private Sub CloseDBConnection
	Main.DBConnector.DBClose
End Sub

Private Sub ReturnApiResponse
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
	
	DB.Table = "tbl_category"
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub GetCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Read one Category by id
	' #Elements = [":id"]

	DB.Table = "tbl_category"
	Dim map As Map = DB.Find(id)
	If map.IsInitialized Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = map
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	End If
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub PostCategory
	' #Plural = Categories
	' #Version = v2
	' #Desc = Add a new Category
	' #Body = {<br>&nbsp;"name": "category_name"<br>}

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If
	' Make it compatible with Web API Client v1
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	If Not(data.ContainsKey("category_name")) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'category_name' not found"
		ReturnApiResponse
		Return
	End If
	
	DB.Table = "tbl_category"
	DB.setWhereValue(Array("category_name = ?"), Array As String(data.Get("category_name")))
	DB.Query

	If DB.Results.Size > 0 Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category already exist"
		CloseDBConnection
		ReturnApiResponse
		Return
	End If

	Dim Columns As List
	Columns.Initialize
	Dim Values As List
	Values.Initialize
	For Each key As String In data.Keys
		Select key
			Case "category_name"
				Columns.Add(key)
				Values.Add(data.Get(key))
			Case "created_date"
				Columns.Add(key)
				Values.Add(WebApiUtils.CurrentDateTime)
			Case Else
				Log(key)
				'Exit
		End Select
	Next

	DB.Reset
	DB.Columns = Columns
	DB.Parameters = Values
	DB.Save

	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Category created successfully"
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub PutCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Update Category by id
	' #Body = {<br>&nbsp;"name": "category_name"<br>}
	' #Elements = [":id"]

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Make it compatible with Web API Client v1
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	If Not(data.ContainsKey("category_name")) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'category_name' not found"
		ReturnApiResponse
		Return
	End If

	DB.Table = "tbl_category"
	DB.Where = Array("category_name = ?", "id <> ?")
	DB.Parameters = Array As String(data.Get("category_name"), id)
	DB.Query
	If DB.First.IsInitialized Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category already exist"
		CloseDBConnection
		ReturnApiResponse
		Return
	End If
	If Not(DB.Find(id).IsInitialized) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
		CloseDBConnection
		ReturnApiResponse
		Return
	End If
						
	Dim Columns As List
	Columns.Initialize
	Dim Values As List
	Values.Initialize
	For Each key As String In data.Keys
		Select key
			Case "category_name"
				Columns.Add(key)
				Values.Add(data.Get(key))
		End Select
	Next

	DB.Reset
	DB.Columns = Columns
	DB.Parameters = Values
	If Not(data.ContainsKey("modified_date")) Then
		DB.UpdateModifiedDate = DB.UseTimestamps
	End If
	DB.Id = id
	DB.Save
	Log(DB.ToString)
	
	HRM.ResponseCode = 200
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Category updated successfully"
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub DeleteCategory (id As Long)
	' #Plural = Categories
	' #Version = v2
	' #Desc = Delete Category by id
	' #Elements = [":id"]

	DB.Table = "tbl_category"
	If Not(DB.Find(id).IsInitialized) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	Else
		DB.Reset
		DB.Id = id
		DB.Delete
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Category deleted successfully"
	End If
	CloseDBConnection
	ReturnApiResponse
End Sub

' Return Web Page
Private Sub ShowPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("category.html")
	Dim strJSFile As String
	Dim strScripts As String
	
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildHtml(strMain, Main.config)
	If Main.SimpleResponse.Enable Then
		If Main.SimpleResponse.Format = "Map" Then
			strJSFile = "webapi.category.simple.map.js"
		Else
			strJSFile = "webapi.category.simple.js"
		End If
	Else
		strJSFile = "webapi.category.js"
	End If
	strScripts = $"<script src="${Main.ROOT_URL}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub