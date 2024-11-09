B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
'Api Handler class
'Version 3.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
	Private Method As String
	Private Elements() As String
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
	Elements = WebApiUtils.CropElements(FullElements, 3)
	Select Method
		Case "GET"
			If ElementMatch("") Then
				GetAllProducts
				Return
			End If
		Case "POST"
			If ElementMatch("") Then
				PostSearchByKeywords
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

Private Sub ReturnErrorUnprocessableEntity 'ignore
	WebApiUtils.ReturnErrorUnprocessableEntity(HRM, Response)
End Sub

Public Sub GetAllProducts
	' #Desc = Read all Products joined by Category
	DB.Table = "tbl_products p"
	DB.Select = Array("p.*", "c.category_name")
	DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
	DB.OrderBy = CreateMap("p.id": "")
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Public Sub PostSearchByKeywords
	' #Desc = Read all Products joined by Category and filter by keywords
	' #Body = {<br>&nbsp;"keywords": "keywords"<br>}
	Dim Data As Map = WebApiUtils.RequestData(Request)
	If Not(Data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check whether required keys are provided
	If Data.ContainsKey("keywords") = False Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Key 'category_name' not found"
		ReturnApiResponse
		Return
	End If
	
	Dim SearchForText As String = Data.Get("keywords")
	
	DB.Table = "tbl_products p"
	DB.Select = Array("p.*", "c.category_name")
	DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
	If SearchForText <> "" Then
		DB.Where = Array("p.product_code LIKE ? Or UPPER(p.product_name) LIKE ? Or UPPER(c.category_name) LIKE ?")
		DB.Parameters = Array("%" & SearchForText & "%", "%" & SearchForText.ToUpperCase & "%", "%" & SearchForText.ToUpperCase & "%")
	End If
	DB.OrderBy = CreateMap("p.id": "")
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub