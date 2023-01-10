B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Category Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Elements() As String
	Private Literals() As String = Array As String("categories", "category") ' Plural, Singular
	Private Const PATH_ELEMENT As Int = Main.Element.Path
	Private Const API_ELEMENT As Int = Main.Element.Api
	Private Const FIRST_ELEMENT As Int = Main.Element.First
	Private Const SECOND_ELEMENT As Int = Main.Element.Second
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Elements = Regex.Split("\/", req.RequestURI)
	Dim SupportedMethods As List = Array As String("GET", "POST", "PUT", "DELETE")
	If Utility.CheckAllowedVerb(SupportedMethods, Request.Method) = False Then
		Utility.ReturnMethodNotAllow(Response)
		Return
	End If
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ApiCall As Boolean
	If Elements.Length > 1 Then
		Dim ApiPathFirstElement As String = Utility.GetAPIPathElements(Main.API_PATH)(0)
		If Elements(Main.Element.Path + 1).EqualsIgnoreCase(ApiPathFirstElement) Then
			Return True
		End If
	End If
	Return False
End Sub

Private Sub ProcessRequest
	Try
		Select Request.Method.ToUpperCase
			Case "GET"
				If ApiCall Then
					Select ElementLastIndex
						Case FIRST_ELEMENT ' /categories
							If Elements(FIRST_ELEMENT) = Literals(0) Then
								Utility.ReturnHttpResponse(GetCategories, Response)
								Return
							End If
						Case SECOND_ELEMENT ' /category/:cid
							'If Elements(FIRST_ELEMENT) = Literals(1) Then
							'	Dim cid As Int = Elements(SECOND_ELEMENT)
							'	Utility.ReturnHttpResponse(GetCategory(cid), Response)
							'	Return
							'End If
							If Elements(FIRST_ELEMENT) = Literals(1) Then
								Select Elements(SECOND_ELEMENT)
									Case "list"	' /category/list
										'ListAll
										Utility.ReturnHttpResponse(ListAll, Response)
										Return
									Case Else
										Dim Id As Int = Elements(SECOND_ELEMENT)
										Utility.ReturnHttpResponse(GetCategory(Id), Response)
										Return
								End Select								
							End If
						Case Else
							Log(ElementLastIndex)
					End Select
				Else ' Web Call
					Dim WEB_FIRST_ELEMENT As Int = FIRST_ELEMENT - API_ELEMENT + PATH_ELEMENT
					Dim WEB_SECOND_ELEMENT As Int = SECOND_ELEMENT - API_ELEMENT + PATH_ELEMENT
					Select ElementLastIndex
						Case WEB_SECOND_ELEMENT
							If Elements(WEB_FIRST_ELEMENT) = Literals(1) Then ' category
								Select Elements(WEB_SECOND_ELEMENT)
									Case "show"	' /category/show
										ShowPage
										Return
								End Select
							End If
						Case Else
							Log(ElementLastIndex)
					End Select
					Utility.ReturnHtmlPageNotFound(Response)
					Return
				End If
			Case "POST"
				Select ElementLastIndex
					Case FIRST_ELEMENT ' /category
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Utility.ReturnHttpResponse(PostCategory, Response)
							Return
						End If
				End Select
			Case "PUT"
				Select ElementLastIndex
					Case SECOND_ELEMENT ' /category/:cid
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							Dim cid As Int = Elements(SECOND_ELEMENT)
							Utility.ReturnHttpResponse(PutCategory(cid), Response)
							Return
						End If
				End Select
			Case "DELETE"
				Select ElementLastIndex
					Case SECOND_ELEMENT ' /category/:cid
						If Elements(FIRST_ELEMENT) = Literals(1) Then
							If ValidateToken = False Then
								Utility.ReturnAuthorizationRequired(Response)
								Return
							End If
							Dim cid As Int = Elements(SECOND_ELEMENT)
							Utility.ReturnHttpResponse(DeleteCategory(cid), Response)
							Return
						End If
				End Select
		End Select
		Utility.ReturnBadRequest(Response)
	Catch
		LogError(LastException)
		Utility.ReturnError("Bad Request", 400, Response)
	End Try
End Sub

Private Sub ShowPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("category.html")
	strMain = Utility.BuildView(strMain, strView)
	
	' Method 1: Use hard coded js
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapicategory.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	
	' Method 2: Use js with template
	'Dim strScript As String = Utility.ReadTextFile("category.js")
	'strMain = Utility.BuildScript2(strMain, strScript, Main.Config)
	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Utility.ReturnHtml(strMain, Response)
End Sub

Private Sub ListAll As HttpResponseMessage ' Don't prefix with Get to hide from documentation
	#region Documentation
	' Desc = Search all categories
	' Elements = ["list"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Try
		Dim strSQL As String = $"SELECT id AS aa, `category_name` AS bb FROM `tbl_category`"$
		Dim res As ResultSet = con.ExecQuery(strSQL)
		
		Dim List1 As List
		List1.Initialize
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "aa" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		'Utility.ReturnSuccess2(List1, 200, Response)
		HRM.ResponseData = List1
	Catch
		LogError(LastException)
		'HRM.Initialize
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
		'Utility.ReturnHttpResponse(HRM, Response)
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub GetCategories As HttpResponseMessage
	#region Documentation
	' #Plural
	' #Desc = List all categories
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.Queries.Get("SELECT_ALL_CATEGORIES") & " ORDER BY Category_Name"
		Dim res As ResultSet = con.ExecQuery(strSQL)
		Dim List1 As List
		List1.Initialize
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "id" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)			
		Loop
		If List1.Size > 0 Then
			HRM.ResponseCode = 200
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Category Not Found"
		End If
		HRM.ResponseData = List1
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub GetCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Desc = Get a category by id
	' #Elements = [":cid"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		' todo: test JWT
		Dim access_token As String = Utility.RequestAccessToken(Request)
		Log(access_token)
		 
		strSQL = Main.Queries.Get("SELECT_CATEGORY_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(cid))
		Dim List1 As List
		List1.Initialize
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "id" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		If List1.Size > 0 Then
			HRM.ResponseCode = 200
			'HRM.ResponseData = List1
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Category Not Found"
		End If
		HRM.ResponseData = List1
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub PostCategory As HttpResponseMessage
	#region Documentation
	' #Desc = Add a new category
	' #Body = {<br>&nbsp; "name": "category_name"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			strSQL = Main.Queries.Get("SELECT_ID_BY_CATEGORY_NAME")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(data.Get("name")))
			If res.NextRow Then
				HRM.ResponseCode = 409
				HRM.ResponseError = "Category Already Exist"
				'Utility.ReturnHttpResponse(HRM, Response)
			Else
				strSQL = Main.Queries.Get("INSERT_NEW_CATEGORY")
				con.BeginTransaction
				con.ExecNonQuery2(strSQL, Array As String(data.Get("name")))
				con.TransactionSuccessful
				strSQL = Main.Queries.Get("GET_LAST_INSERT_ID")
				Dim NewId As Int = con.ExecQuerySingleResult(strSQL)
				strSQL = Main.Queries.Get("SELECT_CATEGORY_BY_ID")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(NewId))
				'con.TransactionSuccessful
				Dim List1 As List
				List1.Initialize
				Do While res.NextRow
					Dim Map2 As Map
					Map2.Initialize
					For i = 0 To res.ColumnCount - 1
						If res.GetColumnName(i) = "id" Then
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
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Invalid JSON input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub PutCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Desc = Update an existing category by id
	' #Elements = [":cid"]
	' #Body = {<br>&nbsp; "name": "category_name"<br>}
	#End region		
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.Queries.Get("SELECT_CATEGORY_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(cid))
		If res.NextRow Then
			Dim data As Map = Utility.RequestData(Request)
			If data.IsInitialized Then
				strSQL = Main.Queries.Get("UPDATE_CATEGORY_BY_ID")
				con.ExecNonQuery2(strSQL, Array As Object(data.Get("name"), cid))
				HRM.ResponseCode = 200
			Else
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid JSON input"
			End If
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Category Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub DeleteCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Desc = Delete a category by id
	' #Elements = [":cid"]
	#End region

	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.Queries.Get("SELECT_CATEGORY_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As Int(cid))
		If res.NextRow Then
			strSQL = Main.Queries.Get("DELETE_CATEGORY_BY_ID")
			con.ExecNonQuery2(strSQL, Array As Int(cid))
			HRM.ResponseCode = 200
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Category Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub ValidateToken As Boolean
	If Main.AUTHENTICATION_TYPE.ToUpperCase = "JSON WEB TOKEN AUTHENTICATION" Then
		Dim Token As String = Utility.RequestAccessToken(Request)
		Main.JAT.Token = Token
		Main.JAT.Verify
		Return Main.JAT.Verified
	Else
		Return True
	End If
End Sub