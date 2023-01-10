B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Product Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Elements() As String
	Private Literals() As String = Array As String("products", "product", "", ":pid") ' Plural, Singular, Action, ID
	Private Const FIRST_ELEMENT As Int = Main.Element.First
	Private Const SECOND_ELEMENT As Int = Main.Element.Second
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Elements = Regex.Split("/", req.RequestURI)
	If Utility.CheckMaxElements(Elements, Main.Element.Max_Elements) = False Then
		Utility.ReturnError("Bad Request", 400, Response)
		Return
	End If
	Dim SupportedMethods As List = Array As String("GET", "POST", "PUT", "DELETE")
	If Utility.CheckAllowedVerb(SupportedMethods, Request.Method) = False Then
		HRM.ResponseCode = 405
		HRM.ResponseError = "Method Not Allowed"
		Utility.ReturnHttpResponse(HRM, Response)
		Return
	End If
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ProcessRequest
	Try
		Select Request.Method.ToUpperCase
			Case "GET"
				Select ElementLastIndex
					Case FIRST_ELEMENT ' /products
						'If Elements(FIRST_ELEMENT) = Literals(0) Then
						'	Utility.ReturnHttpResponse(GetProducts(0), Response)
						'	Return
						'End If
						If Elements(FIRST_ELEMENT) = Literals(0) Then
							Utility.ReturnHttpResponse(GetProducts, Response)
							Return
						End If
					Case SECOND_ELEMENT ' /product/:pid
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Dim pid As Int = Elements(SECOND_ELEMENT)
							Utility.ReturnHttpResponse(GetProduct(pid), Response)
							Return
						End If
				End Select
			Case "POST"
				Select ElementLastIndex
					Case FIRST_ELEMENT ' /product
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Utility.ReturnHttpResponse(PostProduct, Response)
							Return
						End If
				End Select
			Case "PUT"
				Select ElementLastIndex
					Case SECOND_ELEMENT ' /product/:pid
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Dim pid As Int = Elements(SECOND_ELEMENT)
							Utility.ReturnHttpResponse(PutProduct(pid), Response)
							Return
						End If
				End Select
			Case "DELETE"
				Select ElementLastIndex
					Case SECOND_ELEMENT ' /product/{product_id}
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Dim pid As Int = Elements(SECOND_ELEMENT)
							Utility.ReturnHttpResponse(DeleteProduct(pid), Response)
							Return
						End If
				End Select
		End Select
		Utility.ReturnError("Bad Request", 400, Response)
	Catch
		LogError(LastException)
		Utility.ReturnError("Bad Request", 400, Response)
	End Try
End Sub

Private Sub GetProducts As HttpResponseMessage
	#region Documentation
	' #Plural
	' #Desc = List all products
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Dim List1 As List
	List1.Initialize
	Try
		strSQL = Main.Queries.Get("SELECT_ALL_PRODUCTS")
		Dim res As ResultSet = con.ExecQuery(strSQL)
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "product_price" Then
					Map2.Put(res.GetColumnName(i), res.GetDouble2(i))
				Else If res.GetColumnName(i) = "category_id" Or res.GetColumnName(i) = "id" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		If List1.Size > 0 Then
			HRM.ResponseCode = 200
			HRM.ResponseData = List1
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Product Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub GetProduct (pid As Int) As HttpResponseMessage
	#region Documentation
	' #Desc = Get a product by id
	' #Elements = [":pid"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Dim List1 As List
	List1.Initialize
	Try
		strSQL = Main.Queries.Get("SELECT_PRODUCT_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(pid))
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "product_price" Then
					Map2.Put(res.GetColumnName(i), res.GetDouble2(i))
				Else If res.GetColumnName(i) = "category_id" Or res.GetColumnName(i) = "id" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		If List1.Size > 0 Then
			HRM.ResponseCode = 200
			HRM.ResponseData = List1
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Product Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub PostProduct As HttpResponseMessage
	#region Documentation
	' #Desc = Add a new product
	' #Body = {<br>&nbsp; "cat_id": "category_id",<br>&nbsp; "code": "product_code",<br>&nbsp; "name": "product_name",<br>&nbsp; "price": "product_price"<br>}
	#End region	
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			strSQL = Main.Queries.Get("SELECT_ID_BY_PRODUCT_CODE")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(data.Get("code")))
			If res.NextRow Then
				HRM.ResponseCode = 409
				HRM.ResponseError = "Product Code Already Exist"
			Else
				con.BeginTransaction
				strSQL = Main.Queries.Get("INSERT_NEW_PRODUCT")				
				con.ExecNonQuery2(strSQL, Array As String(data.Get("cat_id"), data.Get("code"), data.Get("name"), data.Get("price")))
				strSQL = Main.Queries.Get("GET_LAST_INSERT_ID")
				Dim NewId As Int = con.ExecQuerySingleResult(strSQL)
				strSQL = Main.Queries.Get("SELECT_PRODUCT_BY_ID")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(NewId))
				con.TransactionSuccessful
				Dim List1 As List
				List1.Initialize
				Do While res.NextRow
					Dim Map2 As Map
					Map2.Initialize
					For i = 0 To res.ColumnCount - 1
						If res.GetColumnName(i) = "product_price" Then
							Map2.Put(res.GetColumnName(i), res.GetDouble2(i))
						Else If res.GetColumnName(i) = "category_id" Or res.GetColumnName(i) = "id" Then
							Map2.Put(res.GetColumnName(i), res.GetInt2(i))
						Else
							Map2.Put(res.GetColumnName(i), res.GetString2(i))
						End If
					Next
					List1.Add(Map2)
				Loop
				HRM.ResponseCode = 201
				HRM.ResponseMessage = "Created"
				HRM.ResponseData = List1
			End If
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub PutProduct (pid As Int) As HttpResponseMessage
	' #Desc = Update an existing product by id
	' #Elements = [":pid"]
	' #Body = {<br>&nbsp; "cat_id": "category_id",<br>&nbsp; "code": "product_code",<br>&nbsp; "name": "product_name",<br>&nbsp; "price": "product_price"<br>}
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.Queries.Get("SELECT_PRODUCT_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(pid))
		If res.NextRow Then
			Dim data As Map = Utility.RequestData(Request)
			If data.IsInitialized Then
				strSQL = Main.Queries.Get("UPDATE_PRODUCT_BY_ID")
				con.ExecNonQuery2(strSQL, Array As Object(data.Get("cat_id"), data.Get("code"), data.Get("name"), data.Get("price"), pid))
				HRM.ResponseCode = 200
			Else
				HRM.ResponseCode = 400
			End If
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Product Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub DeleteProduct (pid As Int) As HttpResponseMessage
	' #Desc = Delete a product by id
	' #Elements = [":pid"]
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.Queries.Get("SELECT_PRODUCT_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As Int(pid))
		If res.NextRow Then
			strSQL = Main.Queries.Get("DELETE_PRODUCT_BY_ID")
			con.ExecNonQuery2(strSQL, Array As Int(pid))
			HRM.ResponseCode = 200
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Product Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub