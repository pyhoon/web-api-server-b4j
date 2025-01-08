B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
'Api Handler class
'Version 3.20
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
	Private Method As String
	Private Elements() As String
	Private ElementId As Int
End Sub

Public Sub Initialize
	HRM.Initialize
	HRM.SimpleResponse = Main.Config.SimpleResponse
	DB.Initialize(Main.DBOpen, Main.DBEngine)
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Dim FullElements() As String = WebApiUtils.GetUriElements(Request.RequestURI)
	Elements = WebApiUtils.CropElements(FullElements, 3) ' 3 For Api handler
	Select Method
		Case "GET"
			If ElementMatch("") Then
				GetCategories
				Return
			End If
			If ElementMatch("id") Then
				GetCategoryById(ElementId)
				Return
			End If
		Case "POST"
			If ElementMatch("") Then
				CreateNewCategory
				Return
			End If
		Case "PUT"
			If ElementMatch("id") Then
				PutCategoryById(ElementId)
				Return
			End If
		Case "DELETE"
			If ElementMatch("id") Then
				DeleteCategoryById(ElementId)
				Return
			End If			
		Case Else
			Log("Unsupported method: " & Method)
			ReturnMethodNotAllow
			Return
	End Select
	ReturnBadRequest
End Sub

Private Sub ElementMatch (Pattern As String) As Boolean
	Select Pattern
		Case ""
			If Elements.Length = 0 Then
				Return True
			End If
		Case "id"
			If Elements.Length = 1 Then
				If IsNumber(Elements(0)) Then
					ElementId = Elements(0)
					Return True
				End If
			End If
	End Select
	Return False
End Sub

Private Sub ReturnApiResponse
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Private Sub ReturnBadRequest
	WebApiUtils.ReturnBadRequest(HRM, Response)
End Sub

Private Sub ReturnMethodNotAllow
	WebApiUtils.ReturnMethodNotAllow(HRM, Response)
End Sub

Private Sub GetCategories
	' #Desc = Read all Categories
	' #Authenticate = Basic
	DB.Table = "tbl_categories"
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	ReturnApiResponse
	DB.Close
End Sub

Private Sub GetCategoryById (Id As Int)
	' #Authenticate = Token
	' #Desc = Read one Category by id
	' #Elements = [":id"]
	DB.Table = "tbl_categories"
	DB.Find(Id)
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	End If
	ReturnApiResponse
	DB.Close
End Sub

' Test support for method name which is not starting with verb
'Private Sub PostCategory
Private Sub CreateNewCategory ' #post ' this hashtag will tell HelpHandler that this is a POST endpoint
	' #Authenticate = Token
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Deprecated: Make it compatible with Web API Client v1 (will be removed)
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	' Check whether required keys are provided
	If data.ContainsKey("category_name") = False Then
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
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	' Insert new row
	DB.Reset
	DB.Columns = Array("category_name", "created_date")
	DB.Parameters = Array(data.Get("category_name"), data.GetDefault("created_date", WebApiUtils.CurrentDateTime))
	DB.Save
	
	' Retrieve new row
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Category created successfully"
	ReturnApiResponse
	DB.Close
End Sub

Private Sub PutCategoryById (Id As Int)
	' #Desc = Update Category by id
	' #Body = {<br>&nbsp; "name": "category_name"<br>}
	' #Elements = [":id"]
	' #Authenticate = Token
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Deprecated: Make it compatible with Web API Client v1 (will be removed)
	If data.ContainsKey("name") Then
		data.Put("category_name", data.Get("name"))
		data.Remove("name")
	End If
	
	' Check whether required keys are provided
	If data.ContainsKey("category_name") = False Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'category_name' not found"
		ReturnApiResponse
		Return
	End If
	
	' Check conflict category name
	DB.Table = "tbl_categories"
	DB.Where = Array("category_name = ?", "id <> ?")
	DB.Parameters = Array As String(data.Get("category_name"), Id)
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Category already exist"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Find(Id)
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
		ReturnApiResponse
		DB.Close
		Return
	End If					

	DB.Reset
	DB.Columns = Array("category_name", _
	"modified_date")
	DB.Parameters = Array(data.Get("category_name"), _
	data.GetDefault("created_date", WebApiUtils.CurrentDateTime))
	DB.Id = Id
	DB.Save

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Category updated successfully"
	HRM.ResponseObject = DB.First
	ReturnApiResponse
	DB.Close
End Sub

Private Sub DeleteCategoryById (Id As Int)
	' #Desc = Delete Category by id
	' #Elements = [":id"]
	' #Authenticate = Basic
	DB.Table = "tbl_categories"
	DB.Find(Id)
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Reset
	DB.Id = Id
	DB.Delete
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Category deleted successfully"
	ReturnApiResponse
	DB.Close
End Sub