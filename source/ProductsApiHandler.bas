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
	Elements = WebApiUtils.CropElements(FullElements, 3)
	Select Method
		Case "GET"
			If ElementMatch("") Then
				GetProducts
				Return
			End If
			If ElementMatch("id") Then
				GetProductById(ElementId)
				Return
			End If
		Case "POST"
			If ElementMatch("") Then
				PostProduct
				Return
			End If
		Case "PUT"
			If ElementMatch("id") Then
				PutProductById(ElementId)
				Return
			End If
		Case "DELETE"
			If ElementMatch("id") Then
				DeleteProductById(ElementId)
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

Private Sub GetProducts
	' #Desc = Read all Products
	DB.Table = "tbl_products"
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	ReturnApiResponse
	DB.Close
End Sub

Private Sub GetProductById (Id As Int)
	' #Desc = Read one Product by id
	' #Elements = [":id"]
	DB.Table = "tbl_products"
	DB.Find(Id)
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	End If
	ReturnApiResponse
	DB.Close
End Sub

Private Sub PostProduct
	' #Desc = Add a new Product
	' #Body = {<br>&nbsp; "cat_id": category_id,<br>&nbsp; "code": "product_code",<br>&nbsp; "name": "product_name",<br>&nbsp; "price": 0<br>}
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Deprecated: Make it compatible with Web API Client v1 (will be removed)
	If data.ContainsKey("cat_id") Then
		data.Put("category_id", data.Get("cat_id"))
		data.Remove("cat_id")
	End If
	If data.ContainsKey("code") Then
		data.Put("product_code", data.Get("code"))
		data.Remove("code")
	End If
	If data.ContainsKey("name") Then
		data.Put("product_name", data.Get("name"))
		data.Remove("name")
	End If
	If data.ContainsKey("price") Then
		data.Put("product_price", data.Get("price"))
		data.Remove("price")
	End If
	
	' Check whether required keys are provided
	Dim RequiredKeys As List = Array As String("category_id", "product_code", "product_name") ' "product_price" is optional
	For Each requiredkey As String In RequiredKeys
		If data.ContainsKey(requiredkey) = False Then
			HRM.ResponseCode = 400
			HRM.ResponseError = $"Key '${requiredkey}' not found"$
			ReturnApiResponse
			Return
		End If
	Next
	
	' Check conflict product code
	DB.Table = "tbl_products"
	DB.Where = Array("product_code = ?")
	DB.Parameters = Array As String(data.Get("product_code"))
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product already exist"
		ReturnApiResponse
		DB.Close
		Return
	End If

	' Insert new row
	DB.Reset
	DB.Columns = Array("category_id", _
	"product_code", _
	"product_name", _
	"product_price", _
	"created_date")
	DB.Parameters = Array(data.Get("category_id"), _
	data.Get("product_code"), _
	data.Get("product_name"), _
	data.GetDefault("product_price", 0), _
	data.GetDefault("created_date", WebApiUtils.CurrentDateTime))
	DB.Save

	' Retrieve new row
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Product created successfully"
	ReturnApiResponse
	DB.Close
End Sub

Private Sub PutProductById (Id As Int)
	' #Desc = Update Product by id
	' #Body = {<br>&nbsp; "cat_id": category_id,<br>&nbsp; "code": "product_code",<br>&nbsp; "name": "product_name",<br>&nbsp; "price": 0<br>}
	' #Elements = [":id"]
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Deprecated: Make it compatible with Web API Client v1 (will be removed)
	If data.ContainsKey("cat_id") Then
		data.Put("category_id", data.Get("cat_id"))
		data.Remove("cat_id")
	End If
	If data.ContainsKey("code") Then
		data.Put("product_code", data.Get("code"))
		data.Remove("code")
	End If
	If data.ContainsKey("name") Then
		data.Put("product_name", data.Get("name"))
		data.Remove("name")
	End If
	If data.ContainsKey("price") Then
		data.Put("product_price", data.Get("price"))
		data.Remove("price")
	End If

	' Check conflict product code
	DB.Table = "tbl_products"
	DB.Where = Array("product_code = ?", "id <> ?")
	DB.Parameters = Array As String(data.Get("product_code"), Id)
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Find(Id)
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
		ReturnApiResponse
		DB.Close
		Return
	End If

	DB.Reset
	DB.Columns = Array("category_id", _
	"product_code", _
	"product_name", _
	"product_price", _
	"modified_date")
	DB.Parameters = Array(data.Get("category_id"), _
	data.Get("product_code"), _
	data.Get("product_name"), _
	data.GetDefault("product_price", 0), _
	data.GetDefault("modified_date", WebApiUtils.CurrentDateTime))
	DB.Id = Id
	DB.Save

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product updated successfully"
	HRM.ResponseObject = DB.First
	ReturnApiResponse
	DB.Close
End Sub

Private Sub DeleteProductById (Id As Int)
	' #Desc = Delete Product by id
	' #Elements = [":id"]
	DB.Table = "tbl_products"
	DB.Find(Id)
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Reset
	DB.Id = Id
	DB.Delete
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product deleted successfully"
	ReturnApiResponse
	DB.Close
End Sub