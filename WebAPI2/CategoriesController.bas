B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Api Controller
' Version 1.06
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
	DB.Initialize(Main.DBOpen, Main.DBEngine)
End Sub

Private Sub ReturnApiResponse
	HRM.SimpleResponse = Main.SimpleResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(Response)
End Sub

Private Sub ReturnErrorUnprocessableEntity
	WebApiUtils.ReturnErrorUnprocessableEntity(Response)
End Sub

' Api Router
Public Sub RouteApi
	Method = Request.Method.ToUpperCase
	Elements = WebApiUtils.GetUriElements(Request.RequestURI)
	ApiVersionIndex = Main.Element.ApiVersionIndex
	ControllerIndex = Main.Element.ApiControllerIndex
	Version = Elements(ApiVersionIndex)
	ElementLastIndex = Elements.Length - 1
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
			ReturnMethodNotAllow
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
			ReturnMethodNotAllow
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
					If IsNumber(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					GetCategory(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
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
	ReturnBadRequest
End Sub

' Router for PUT request
Private Sub RoutePut
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If IsNumber(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					PutCategory(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

' Router for DELETE request
Private Sub RouteDelete
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case FirstIndex
					If IsNumber(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					DeleteCategory(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub GetCategories
	' #Version = v2
	' #Desc = Read all Categories

    DB.Table = "tbl_categories"
    DB.Query
    HRM.ResponseCode = 200
    HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Private Sub GetCategory (id As Long)
	' #Version = v2
	' #Desc = Read one Category by id
	' #Elements = [":id"]

    DB.Table = "tbl_categories"
	DB.Find(id)
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostCategory
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
	
	' Check whether required keys are provided
	If Not(data.ContainsKey("category_name")) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'category_name' not found"
		ReturnApiResponse
		Return
	End If
	
	' Check conflict category name
	DB.Table = "tbl_categories"
	DB.Where = Array("category_name = ?")
	DB.Parameters = Array As String(data.Get("category_name"))
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category already exist"
		DB.Close
		ReturnApiResponse
		Return
	End If
	
	' Adding parameters to list
	Dim Columns As List
	Columns.Initialize
	Dim Values As List
	Values.Initialize
	For Each key As String In data.Keys
		Select key
			Case "category_name", "created_date"
				Columns.Add(key)
				Values.Add(data.Get(key))
			Case Else
				Log(key)
		End Select
	Next
	
	' Insert new row
	DB.Reset
	DB.Columns = Columns
	DB.Parameters = Values
	DB.Save
	
	' Retrieve new row
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Category created successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PutCategory (id As Long)
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

	DB.Table = "tbl_categories"
	DB.Where = Array("category_name = ?", "id <> ?")
	DB.Parameters = Array As String(data.Get("category_name"), id)
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category already exist"
		DB.Close
		ReturnApiResponse
		Return
	End If
	
	DB.Find(id)
	If Not(DB.Found) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
		DB.Close
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
		DB.UpdateModifiedDate = True
	End If
	DB.Id = id
	DB.Save

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Category updated successfully"
	HRM.ResponseObject = DB.First
	DB.Close
	ReturnApiResponse
End Sub

' Router for DELETE request
Private Sub DeleteCategory (id As Long)
	' #Version = v2
	' #Desc = Delete Category by id
	' #Elements = [":id"]
	
	DB.Table = "tbl_categories"
	DB.Find(id)
	If DB.Found Then
		DB.Reset
		DB.Id = id
		DB.Delete
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Category deleted successfully"
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	End If
	DB.Close
	ReturnApiResponse	
End Sub

' Return Web Page
Private Sub ShowPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("category.html")
	Dim strHelp As String
	Dim strJSFile As String
	Dim strScripts As String
	
	If Main.SHOW_API_ICON Then
		strHelp = $"        <li class="nav-item">
          <a class="nav-link mr-3 font-weight-bold text-white" href="${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}help"><i class="fas fa-cog" title="API"></i> API</a>
	</li>"$
	Else
		strHelp = ""
	End If
	
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", strHelp)
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
	strScripts = $"<script src="${Main.Config.Get("ROOT_URL")}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub