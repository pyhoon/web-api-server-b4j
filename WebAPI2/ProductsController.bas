B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Api Controller
' Version 1.05
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
	DB.Initialize(Main.DBOpen, Main.DBEngine)
End Sub

Private Sub ReturnApiResponse
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

' Router for GET request
Private Sub RouteGet
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					GetProducts
					Return
				Case FirstIndex
					If IsNumber(FirstElement) = False Then
						ReturnErrorUnprocessableEntity
						Return
					End If
					GetProduct(FirstElement)
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
					PostProduct
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
					PutProduct(FirstElement)
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
					DeleteProduct(FirstElement)
					Return
			End Select
	End Select
	ReturnBadRequest
End Sub

Private Sub GetProducts
	' #Version = v2
	' #Desc = Read all Products

    DB.Table = "tbl_products"
    DB.Query
    HRM.ResponseCode = 200
    HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Private Sub GetProduct (id As Long)
	' #Version = v2
	' #Desc = Read one Product by id
	' #Elements = [":id"]

    DB.Table = "tbl_products"
	DB.Find(id)
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	End If
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PostProduct
	' #Version = v2
	' #Desc = Add a new Product
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Make it compatible with Web API Client v1
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
		If Not(data.ContainsKey(requiredkey)) Then
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
			Case "category_id", "product_code", "product_name", "product_price", "created_date"
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

	' Retrive new row
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Product created successfully"
	DB.Close
	ReturnApiResponse
End Sub

Private Sub PutProduct (id As Long)
	' #Version = v2
	' #Desc = Update Product by id
	' #Body = {<br>&nbsp;"cat_id": category_id,<br>&nbsp;"code": "product_code",<br>&nbsp;"name": "product_name",<br>&nbsp;"price": product_price<br>}
	' #Elements = [":id"]

	Dim data As Map = WebApiUtils.RequestData(Request)
	If Not(data.IsInitialized) Then
		HRM.ResponseCode = 400
		HRM.ResponseError = "Invalid json object"
		ReturnApiResponse
		Return
	End If

	' Make it compatible with Web API Client v1
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
	DB.Parameters = Array As String(data.Get("product_code"), id)
	DB.Query
	If DB.Found Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		DB.Close
		ReturnApiResponse
		Return
	End If
	
	DB.Find(id)
	If Not(DB.Found) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
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
			Case "category_id", "product_code", "product_name", "product_price", "modified_date"
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
	HRM.ResponseMessage = "Product updated successfully"
	HRM.ResponseObject = DB.First
	DB.Close
	ReturnApiResponse
End Sub

Private Sub DeleteProduct (id As Long)
	' #Version = v2
	' #Desc = Delete Product by id
	' #Elements = [":id"]
	
	DB.Table = "tbl_products"
	DB.Find(id)
	If DB.Found Then
		DB.Reset
		DB.Id = id
		DB.Delete
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Product deleted successfully"
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	End If
	DB.Close
	ReturnApiResponse	
End Sub