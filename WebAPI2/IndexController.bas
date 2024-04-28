B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Web Controller
' Version 1.05
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private DB As MiniORM
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

Public Sub Show
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strView As String = WebApiUtils.ReadTextFile("index.html")
	Dim strHelp As String
	Dim strJSFile As String
	Dim strScripts As String
	
	If Main.SHOW_API_ICON Then
		strHelp = $"        <li class="nav-item">
          <a class="nav-link mr-3 font-weight-bold text-white" href="${Main.Config.Get("ROOT_URL")}${Main.Config.Get("ROOT_PATH")}help"><i class="fas fa-cog" title="API"></i> API</a>
	</li>"$
	Else
		strHelp = ""
	End If
	
	strMain = WebApiUtils.BuildDocView(strMain, strView)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", strHelp)
	strMain = WebApiUtils.BuildHtml(strMain, Main.Config)
	If Main.SimpleResponse.Enable Then
		If Main.SimpleResponse.Format = "Map" Then
			strJSFile = "webapi.search.simple.map.js"
		Else
			strJSFile = "webapi.search.simple.js"
		End If		
	Else
		strJSFile = "webapi.search.js"
	End If
	strScripts = $"<script src="${Main.Config.Get("ROOT_URL")}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHTML(strMain, Response)
End Sub

Public Sub GetSearch
	DB.Table = "tbl_products p"
	DB.Select = Array("p.*", "c.category_name")
	DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
	DB.OrderBy = CreateMap("p.id": "")
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub

Public Sub PostSearch
	Dim SearchForText As String
	Dim Data As Map = WebApiUtils.RequestData(Request)
	If Data.IsInitialized Then
		SearchForText = Data.Get("keywords")
	End If

	DB.Table = "tbl_products p"
	DB.Select = Array("p.*", "c.category_name")
	DB.Join = DB.CreateORMJoin("tbl_categories c", "p.category_id = c.id", "")
	If SearchForText <> "" Then
		DB.Where = Array("p.product_code LIKE ? Or UPPER(p.product_name) LIKE ? Or UPPER(c.category_name) LIKE ?")
		DB.Parameters = Array("%" & SearchForText & "%", "%" & SearchForText.ToUpperCase & "%", "%" & SearchForText.ToUpperCase & "%")
	End If
	DB.OrderBy = CreateMap("p.id": "")
	DB.Query
	HRM.ResponseCode = 200
	HRM.ResponseData = DB.Results
	DB.Close
	ReturnApiResponse
End Sub