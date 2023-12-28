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

' Router for GET request
Private Sub RouteGet
	Select Version
		Case "v2"
			Select ElementLastIndex
				Case ControllerIndex
					GetProducts
					Return
				Case FirstIndex					
					If WebApiUtils.CheckInteger(FirstElement) = False Then
						WebApiUtils.ReturnErrorUnprocessableEntity(Response)
						Return
					End If
					GetProduct(FirstElement)
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
					PostProduct
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
					PutProduct(FirstElement)
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
					DeleteProduct(FirstElement)
					Return
			End Select
	End Select
	WebApiUtils.ReturnBadRequest(Response)
End Sub

Private Sub GetProducts
	' #Plural = Products
	' #Version = v2
	' #Desc = Read all Products

	DB.Table = "tbl_products"
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub GetProduct (id As Long)
	' #Plural = Products
	' #Version = v2
	' #Desc = Read one Product by id
	' #Elements = [":id"]
	
	DB.Table = "tbl_products"
	Dim map As Map = DB.Find(id)
	If map.IsInitialized Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = map
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	End If
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub PostProduct
	' #Plural = Products
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
	If DB.Results.Size > 0 Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		CloseDBConnection
		ReturnApiResponse
		Return
	End If
	' Adding parameters to list
	Dim columns As List
	columns.Initialize
	Dim Values As List
	Values.Initialize
	For Each key As String In data.Keys
		Select key
			Case "category_id", "product_code", "product_name", "product_price", "created_date"
				columns.Add(key)
				Values.Add(data.Get(key))
			Case Else
				Log(key)
				Exit
		End Select
	Next
	' Insert new row
	DB.Reset
	DB.Columns = columns
	DB.Parameters = Values
	DB.Save
	' Retrive new row
	HRM.ResponseCode = 201
	HRM.ResponseObject = DB.First
	HRM.ResponseMessage = "Product created successfully"
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub PutProduct (id As Long)
	' #Plural = Products
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
	If DB.First.IsInitialized Then
		HRM.ResponseCode = 409
		HRM.ResponseError = "Product Code already exist"
		CloseDBConnection
		ReturnApiResponse
		Return
	End If
	If Not(DB.Find(id).IsInitialized) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
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
			Case "category_id", "product_code", "product_name", "product_price", "modified_date"
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
	HRM.ResponseObject = DB.First ' DB.Find(id) ' comment this line to show message as object
	HRM.ResponseMessage = "Product updated successfully"
	CloseDBConnection
	ReturnApiResponse
End Sub

Private Sub DeleteProduct (id As Long)
	' #Plural = Products
	' #Version = v2
	' #Desc = Delete Product by id
	' #Elements = [":id"]

	DB.Table = "tbl_products"
	If Not(DB.Find(id).IsInitialized) Then
		HRM.ResponseCode = 404
		HRM.ResponseError = "Product not found"
	Else
		DB.Reset
		DB.Id = id
		DB.Delete
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Product deleted successfully"
	End If
	CloseDBConnection
	ReturnApiResponse
End Sub