B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Category Controller Class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Public Sub ShowPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("category.html")
	strMain = Utility.BuildView(strMain, strView)
	
	' Method 1: Use hard coded js
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.category.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	
	' Method 2: Use js with template
	'Dim strScript As String = Utility.ReadTextFile("category.js")
	'strMain = Utility.BuildScript2(strMain, strScript, Main.Config)
	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub GetCategoriesSortedBy (col As String) As HttpResponseMessage
	#region Documentation
	' #Hide
	' #Desc = List all categories sorted by id/name
	' #Elements = ["sort", ":col"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Try
		Dim strSQL As String = $"SELECT `id` AS aa, `Category_Name` AS bb FROM `tbl_category`"$
		Select col.ToLowerCase
			Case "id"
				strSQL = strSQL & " ORDER BY `id`"
			Case "name"
				strSQL = strSQL & " ORDER BY `Category_Name`"
		End Select
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
		HRM.ResponseCode = 200
		HRM.ResponseData = List1
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub GetCategories As HttpResponseMessage
	#region Documentation
	' #Plural = categories
	' #Version = v2
	' #Desc = List all categories
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.DB.Queries.Get("SELECT_ALL_CATEGORIES")
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

Public Sub GetCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Get a category by id
	' #Elements = [":cid"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try	 
		strSQL = Main.DB.Queries.Get("SELECT_CATEGORY_BY_ID")
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

Public Sub PostCategory As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Add a new category
	' #Body = {<br>&nbsp; "name": "category_name"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			strSQL = Main.DB.Queries.Get("SELECT_ID_BY_CATEGORY_NAME")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(data.Get("name")))
			If res.NextRow Then
				HRM.ResponseCode = 409
				HRM.ResponseError = "Category Already Exist"
			Else
				strSQL = Main.DB.Queries.Get("INSERT_NEW_CATEGORY")
				con.BeginTransaction
				con.ExecNonQuery2(strSQL, Array As String(data.Get("name")))
				con.TransactionSuccessful
				strSQL = Main.DB.Queries.Get("GET_LAST_INSERT_ID")
				Dim NewId As Int = con.ExecQuerySingleResult(strSQL)
				strSQL = Main.DB.Queries.Get("SELECT_CATEGORY_BY_ID")
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

Public Sub PutCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Update an existing category by id
	' #Elements = [":cid"]
	' #Body = {<br>&nbsp; "name": "category_name"<br>}
	#End region		
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.DB.Queries.Get("SELECT_CATEGORY_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(cid))
		If res.NextRow Then
			Dim data As Map = Utility.RequestData(Request)
			If data.IsInitialized Then
				strSQL = Main.DB.Queries.Get("UPDATE_CATEGORY_BY_ID")
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

Public Sub DeleteCategory (cid As Int) As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Delete a category by id
	' #Elements = [":cid"]
	#End region

	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.DB.Queries.Get("SELECT_CATEGORY_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As Int(cid))
		If res.NextRow Then
			strSQL = Main.DB.Queries.Get("DELETE_CATEGORY_BY_ID")
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