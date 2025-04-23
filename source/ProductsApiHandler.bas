B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
'Api Handler class
'Version 3.42
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
	HRM.SimpleResponse = Main.conf.SimpleResponse
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
	DB.Initialize(Main.DBType, Main.DBOpen)
	DB.Table = "tbl_products"
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	ReturnApiResponse
	DB.Close
End Sub

Private Sub GetProductById (id As Int)
	DB.Initialize(Main.DBType, Main.DBOpen)
	DB.Table = "tbl_products"
	DB.Find(id)
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
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
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
	DB.Initialize(Main.DBType, Main.DBOpen)
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

Private Sub PutProductById (id As Int)
	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Check conflict product code
	DB.Initialize(Main.DBType, Main.DBOpen)
	DB.Table = "tbl_products"
	DB.Where = Array("product_code = ?", "id <> ?")
	DB.Parameters = Array As String(data.Get("product_code"), id)
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Find(id)
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
	DB.Id = id
	DB.Save

	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product updated successfully"
	HRM.ResponseObject = DB.First
	ReturnApiResponse
	DB.Close
End Sub

Private Sub DeleteProductById (id As Int)
	DB.Initialize(Main.DBType, Main.DBOpen)
	DB.Table = "tbl_products"
	DB.Find(id)
	If DB.Found = False Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
		ReturnApiResponse
		DB.Close
		Return
	End If
	
	DB.Reset
	DB.Id = id
	DB.Delete
	HRM.ResponseCode = 200
	HRM.ResponseMessage = "Product deleted successfully"
	ReturnApiResponse
	DB.Close
End Sub