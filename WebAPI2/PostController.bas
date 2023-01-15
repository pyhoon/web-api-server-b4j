B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Post Controller Class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse 'ignore
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
End Sub

Public Sub GetPosts As HttpResponseMessage
	#region Documentation
	' #Plural = posts
	' #Version = v2
	' #Desc = List all posts
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Dim List1 As List
	List1.Initialize
	Try
		strSQL = Main.DB.Queries.Get("SELECT_ALL_POSTS")
		Dim res As ResultSet = con.ExecQuery(strSQL)
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "id" Or _
					res.GetColumnName(i) = "category_id" Or _
					res.GetColumnName(i) = "post_status" Then
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

Public Sub GetPost (pid As Int) As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Get a post by id
	' #Elements = [":pid"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Dim List1 As List
	List1.Initialize
	Try
		strSQL = Main.DB.Queries.Get("SELECT_POST_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(pid))
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "id" Or _
					res.GetColumnName(i) = "category_id" Or _
					res.GetColumnName(i) = "post_status" Then
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
			HRM.ResponseError = "Post Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub PostPost As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Add a new post
	' #Body = {<br>&nbsp; "cat_id": "category_id",<br>&nbsp; "slug": "slug",<br>&nbsp; "title": "post_title",<br>&nbsp; "body": "post_body"<br>&nbsp; "status": "post_status"<br>}
	#End region	
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			strSQL = Main.DB.Queries.Get("SELECT_ID_BY_POST_SLUG")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(data.Get("slug")))
			If res.NextRow Then
				HRM.ResponseCode = 409
				HRM.ResponseError = "Post Slug Already Exist"
			Else
				con.BeginTransaction
				strSQL = Main.DB.Queries.Get("INSERT_NEW_POST")
				con.ExecNonQuery2(strSQL, Array As String(data.Get("cat_id"), data.Get("slug"), data.Get("title"), data.Get("body"), data.Get("status")))
				strSQL = Main.DB.Queries.Get("GET_LAST_INSERT_ID")
				Dim NewId As Int = con.ExecQuerySingleResult(strSQL)
				strSQL = Main.DB.Queries.Get("SELECT_POST_BY_ID")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(NewId))
				con.TransactionSuccessful
				Dim List1 As List
				List1.Initialize
				Do While res.NextRow
					Dim Map2 As Map
					Map2.Initialize
					For i = 0 To res.ColumnCount - 1
						If res.GetColumnName(i) = "id" Or _
							res.GetColumnName(i) = "category_id" Or _
							res.GetColumnName(i) = "post_status" Then
							Map2.Put(res.GetColumnName(i), res.GetInt2(i))
						Else
							Map2.Put(res.GetColumnName(i), res.GetString2(i))
						End If
					Next
					List1.Add(Map2)
				Loop
				HRM.ResponseCode = 201
				HRM.ResponseMessage = "New Post Created"
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

Public Sub PutPost (pid As Int) As HttpResponseMessage
	' #Version = v2
	' #Desc = Update an existing post by id
	' #Elements = [":pid"]
	' #Body = {<br>&nbsp; "cat_id": "category_id",<br>&nbsp; "slug": "slug",<br>&nbsp; "title": "post_title",<br>&nbsp; "body": "post_body"<br>&nbsp; "status": "post_status"<br>}
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.DB.Queries.Get("SELECT_POST_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(pid))
		If res.NextRow Then
			Dim data As Map = Utility.RequestData(Request)
			If data.IsInitialized Then
				strSQL = Main.DB.Queries.Get("UPDATE_POST_BY_ID")
				con.ExecNonQuery2(strSQL, Array As String(data.Get("cat_id"), data.Get("slug"), data.Get("title"), data.Get("body"), data.Get("status"), pid))
				HRM.ResponseCode = 200
			Else
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid JSON input"
			End If
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Post Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub DeletePost (pid As Int) As HttpResponseMessage
	' #Version = v2
	' #Desc = Delete a post by id
	' #Elements = [":pid"]
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		strSQL = Main.DB.Queries.Get("SELECT_POST_BY_ID")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As Int(pid))
		If res.NextRow Then
			strSQL = Main.DB.Queries.Get("DELETE_POST_BY_ID")
			con.ExecNonQuery2(strSQL, Array As Int(pid))
			HRM.ResponseCode = 200
		Else
			HRM.ResponseCode = 404
			HRM.ResponseError = "Post Not Found"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub