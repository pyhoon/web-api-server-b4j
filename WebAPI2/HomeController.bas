B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Home Controller class
' Version 2.00
Sub Class_Globals
	'Private Request As ServletRequest
	Private Response As ServletResponse
End Sub

Public Sub Initialize (resp As ServletResponse)
	Response = resp
End Sub

Public Sub ShowHomePage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("index.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.search.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub Search (SearchForText As String)
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim keys() As String = Regex.Split2(" ", 2, SearchForText)

		If keys.Length < 2 Then
			Dim s1 As String = SearchForText.Trim
			'Log(s1)
			If s1 = "" Then
				strSQL = $"SELECT P.id AS aa,
				P.post_slug AS bb,
				C.category_name AS cc,
				P.post_title AS dd,
				P.post_body AS ee,
				P.post_status AS ff,
				P.created_date AS gg,
				P.category_id AS hh
				FROM tbl_posts P JOIN tbl_category C ON P.category_id = C.id"$
				Dim res As ResultSet = con.ExecQuery(strSQL)
			Else
				strSQL = Main.DB.Queries.Get("SEARCH_POST_BY_CATEGORY_TITLE_AND_BODY_ONEWORD_ORDERED")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String("%" & s1 & "%", "%" & s1 & "%", "%" & s1 & "%"))
			End If
		Else
			Dim s1 As String = keys(0).Trim
			Dim s2 As String = SearchForText.Replace(keys(0), "").Trim
			'Log(s1 & "," & s2)
			strSQL = Main.DB.Queries.Get("SEARCH_POST_BY_CATEGORY_TITLE_AND_BODY_TWOWORDS_ORDERED")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String("%" & s1 & "%", "%" & s1 & "%", "%" & s1 & "%", _
			"%" & s2 & "%", "%" & s2 & "%", "%" & s2 & "%"))
		End If

		Dim List1 As List
		List1.Initialize
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "aa" Or _
					res.GetColumnName(i) = "ff" Or _
					res.GetColumnName(i) = "hh" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		Utility.ReturnSuccess2(List1, 200, Response)
	Catch
		LogError(LastException)
		Utility.ReturnErrorExecuteQuery(Response)
	End Try
	Main.DB.CloseDB(con)
End Sub