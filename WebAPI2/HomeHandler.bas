B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=8.1
@EndOfDesignText@
' Home Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	' Search e.g. ' http://127.0.0.1:19800/v1/?search=ha
	If Request.GetParameter("search") <> "" Then ' GET
		Search(Request.GetParameter("search"))
	Else If Request.GetParameter("default") <> "" Then ' GET
		Search("")
	Else if Request.Method.ToUpperCase = "POST" Then
		Dim keywords As String = req.GetParameter("keywords").Trim
		Search(keywords)
	Else
		ShowHomePage
	End If
End Sub

Private Sub ShowHomePage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("index.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapisearch.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	Utility.ReturnHtml(strMain, Response)
End Sub

Private Sub Search (SearchForText As String)
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim keys() As String = Regex.Split2(" ", 2, SearchForText)

		If keys.Length < 2 Then
			Dim s1 As String = SearchForText.Trim
			'Log(s1)
			'strSQL = Main.Queries.Get("SEARCH_PRODUCT_BY_CATEGORY_CODE_AND_NAME_ONEWORD_ORDERED")
			'Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String("%" & s1 & "%", "%" & s1 & "%", "%" & s1 & "%"))
			If s1 = "" Then
				strSQL = $"SELECT P.id As aa, P.product_code As bb, C.`category_name` As cc, P.product_name As dd, P.product_price As ee, P.`category_id` As ff
				FROM `tbl_products` P JOIN `tbl_category` C ON P.`category_id` = C.`id`"$
				Dim res As ResultSet = con.ExecQuery(strSQL)
			Else
				strSQL = Main.Queries.Get("SEARCH_PRODUCT_BY_CATEGORY_CODE_AND_NAME_ONEWORD_ORDERED")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String("%" & s1 & "%", "%" & s1 & "%", "%" & s1 & "%"))
			End If
		Else
			Dim s1 As String = keys(0).Trim
			Dim s2 As String = SearchForText.Replace(keys(0), "").Trim
			'Log(s1 & "," & s2)
			strSQL = Main.Queries.Get("SEARCH_PRODUCT_BY_CATEGORY_CODE_AND_NAME_TWOWORDS_ORDERED")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String("%" & s1 & "%", "%" & s1 & "%", "%" & s1 & "%", _
			"%" & s2 & "%", "%" & s2 & "%", "%" & s2 & "%"))
		End If

		Dim List1 As List
		List1.Initialize
		Do While res.NextRow
			Dim Map2 As Map
			Map2.Initialize
			For i = 0 To res.ColumnCount - 1
				If res.GetColumnName(i) = "aa" Or res.GetColumnName(i) = "ff" Then
					Map2.Put(res.GetColumnName(i), res.GetInt2(i))
				Else If res.GetColumnName(i) = "ee" Then
					Map2.Put(res.GetColumnName(i), NumberFormat2(res.GetDouble2(i), 1, 2, 2, True))
				Else
					Map2.Put(res.GetColumnName(i), res.GetString2(i))
				End If
			Next
			List1.Add(Map2)
		Loop
		Utility.ReturnSuccess2(List1, 200, Response)
	Catch
		LogError(LastException)
		HRM.Initialize
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
		Utility.ReturnHttpResponse(HRM, Response)
	End Try
	Main.DB.CloseDB(con)
End Sub