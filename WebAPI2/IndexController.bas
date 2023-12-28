B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Web Controller
' Version 1.03
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

Private Sub ReturnApiResponse
	HRM.SimpleResponse.Simple = Main.SimpleResponse
	HRM.SimpleResponse.Format = Main.SimpleResponseFormat
	HRM.SimpleResponse.DataKey = Main.SimpleResponseDataKey
	WebApiUtils.ReturnHttpResponse(HRM, Response)
End Sub

Public Sub Show
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildHtml(strMain, Main.config)
	If Main.SimpleResponse Then
		If Main.SimpleResponseFormat = "Map" Then
			Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapisearch-simple-map.js"></script>"$
		Else
			Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapisearch-simple.js"></script>"$
		End If		
	Else
		Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapisearch.js"></script>"$
	End If
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub

Public Sub GetSearch
	#If MinimaList
	Dim list As List
	list.Initialize
	Dim L1 As List = WebApiUtils.CopyObject( Main.ProductList.List )
	For Each M1 As Map In L1
		Dim catid As Long = M1.Get("category_id")
		Dim category_name As String = Main.CategoryList.Find(catid).Get("category_name")
		M1.Put("category_name", category_name)
		list.Add(M1)
	Next
	HRM.ResponseCode = 200
	HRM.ResponseData = list
	ReturnApiResponse
	#End If
	
	#If Not(MinimaList) And Not(No_Database)
	Dim list As List
	list.Initialize
		
	Dim con As SQL = Main.DBConnector.DBOpen
	Dim qry As String = "SELECT p.*, c.category_name FROM tbl_products p JOIN tbl_category c ON p.category_id = c.id ORDER BY p.id"
	Dim rs As ResultSet = con.ExecQuery(qry)
	Do While rs.NextRow
		Dim map As Map
		map.Initialize
		For i = 0 To rs.ColumnCount - 1
			Select rs.GetColumnName(i)
				Case "id"
					map.Put(rs.GetColumnName(i), rs.GetInt2(i))
				Case "product_price"
					map.Put(rs.GetColumnName(i), rs.GetDouble2(i))
				Case Else
					map.Put(rs.GetColumnName(i), rs.GetString2(i))
			End Select
		Next
		list.Add(map)
	Loop
	rs.Close
				
	HRM.ResponseCode = 200
	HRM.ResponseData = list
		
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

Public Sub PostSearch
	Dim SearchForText As String
	Dim Data As Map = WebApiUtils.RequestData(Request)
	If Data.IsInitialized Then
		SearchForText = Data.Get("keywords")
	End If
	
	#If MinimaList
	If SearchForText = "" Then
		Dim L1 As List = WebApiUtils.CopyObject(Main.ProductList.List)
		HRM.ResponseCode = 200
		HRM.ResponseData = L1
	Else
		Dim CombineList As List
		CombineList.Initialize
		Dim list As List = WebApiUtils.CopyObject(Main.ProductList.List)
		For Each m1 As Map In list
			Dim catid As Long = m1.Get("category_id")
			Dim category_name As String = Main.CategoryList.Find(catid).Get("category_name")
			m1.Put("category_name", category_name)
			CombineList.Add(m1)
		Next
		Dim CL As MinimaList
		CL.Initialize
		CL.List = CombineList
		Dim L1 As List = CL.FindAnyLike(Array("product_code", "product_name", "category_name"), Array As String(SearchForText, SearchForText, SearchForText))
		If L1.Size > 0 Then
			For Each m1 As Map In L1
				Dim catid As Long = m1.Get("category_id")
				Dim category_name As String = Main.CategoryList.Find(catid).Get("category_name")
				m1.Put("category_name", category_name)
			Next
		End If
		HRM.ResponseCode = 200
		HRM.ResponseData = L1
	End If
	ReturnApiResponse
	#End If
	
	#If Not(MinimaList) And Not(No_Database)
	Dim list As List
	list.Initialize
	
	Dim con As SQL = Main.DBConnector.DBOpen
	If SearchForText = "" Then
		Dim qry As String = $"SELECT p.*, c.category_name FROM tbl_products p
		JOIN tbl_category c ON p.category_id = c.id
		ORDER BY p.id"$
		Dim rs As ResultSet = con.ExecQuery(qry)
	Else
		Dim qry As String = $"SELECT p.*, c.category_name FROM tbl_products p
		JOIN tbl_category c ON p.category_id = c.id
		WHERE product_code LIKE ? Or product_name LIKE ? Or category_name LIKE ?
		ORDER BY p.id"$
		Dim rs As ResultSet = con.ExecQuery2(qry, _
		Array("%" & SearchForText & "%", _
		"%" & SearchForText & "%", _
		"%" & SearchForText & "%"))
	End If
	Do While rs.NextRow
		Dim map As Map
		map.Initialize
		For i = 0 To rs.ColumnCount - 1
			Select rs.GetColumnName(i)
				Case "id"
					map.Put(rs.GetColumnName(i), rs.GetInt2(i))
				Case "product_price"
					map.Put(rs.GetColumnName(i), rs.GetDouble2(i))
				Case Else
					map.Put(rs.GetColumnName(i), rs.GetString2(i))
			End Select
		Next
		list.Add(map)
	Loop
	rs.Close
		
	HRM.ResponseCode = 200
	HRM.ResponseData = list
	
	Main.DBConnector.DBClose
	ReturnApiResponse
	#End If
End Sub

#If MinimaList
Public Sub SeedData
	' #Desc = Seed some dummy data in MimimaList
	If Main.CategoryList.List.Size = 0 Then
		Dim M1 As Map = CreateMap("category_name": "Hardwares", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoryList.Add(M1)
		Dim M1 As Map = CreateMap("category_name": "Toys", "created_date": WebApiUtils.CurrentDateTime)
		Main.CategoryList.Add(M1)
		If Main.KVS_ENABLED Then Main.WriteKVS("CategoryList", Main.CategoryList)
	End If

	If Main.ProductList.List.Size = 0 Then
		Dim M2 As Map = CreateMap("category_id": 2, _
		"product_code": "T001", _
		"product_name": "Teddy Bear", _
		"product_price": 99.9, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductList.Add(M2)
		Dim M2 As Map = CreateMap("category_id": 1, _
		"product_code": "H001", _
		"product_name": "Hammer", _
		"product_price": 15.75, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductList.Add(M2)
		Dim M2 As Map = CreateMap("category_id": 2, _
		"product_code": "T002", _
		"product_name": "Optimus Prime", _
		"product_price": 1000, _
		"created_date": WebApiUtils.CurrentDateTime)
		Main.ProductList.Add(M2)
		If Main.KVS_ENABLED Then Main.WriteKVS("ProductList", Main.ProductList)
	End If
	WebApiUtils.ReturnLocation(Main.ROOT_PATH, Response)
End Sub
#End If