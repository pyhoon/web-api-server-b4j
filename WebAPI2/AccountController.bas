B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Account Controller class
' Version 2.00
' Additional Modules: Utility, MiniORM, JSONWebToken
' Additional Libraries: jNet, jServer, jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private HRT As HttpResponseContent
	Private Model As Map
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
	HRT.Initialize
	Model.Initialize
End Sub

Public Sub ShowAccountPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("account.html")
	strMain = Utility.BuildView(strMain, strView)
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	' Method 1: Use hard coded js
	Dim strScripts As String '= $"<script src="${Main.ROOT_URL}/assets/js/webapi.account.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	
	' Method 2: Use js with template
	'Dim strScript As String = Utility.ReadTextFile("account.js")
	'strMain = Utility.BuildScript2(strMain, strScript, Main.Config)
	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub ShowRegisterPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("register.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.account.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	'strMain = Utility.BuildScript(strMain, "")
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub ShowLoginPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("login.html")
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	strMain = Utility.BuildView(strMain, strView)
	If Main.SESSIONS_ENABLED Then
		' Store csrf_token inside server session variables
		Dim csrf_token As String = Encryption.RandomHash2
		Request.GetSession.SetAttribute(Main.PREFIX & "csrf_token", csrf_token)
		strMain = Utility.BuildCsrfToken(strMain, csrf_token) 		' Append csrf_token into page header. Comment this line to check
	End If	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.account.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	'strMain = Utility.BuildScript(strMain, "")
	Utility.ReturnHtml(strMain, Response)
End Sub

' Download Admin dashboard template
' https://github.com/colorlibhq/AdminLTE
Public Sub ShowDashboardPage
	Dim strMain As String = Utility.ReadTextFile("index3.html")
	strMain = Utility.BuildHtml(strMain, Main.Config)
	If Main.SESSIONS_ENABLED Then
		Dim user_name As String = Request.GetSession.GetAttribute2(Main.PREFIX & "username", "")
		Model.Put("user_name", Utility.DecodeURL(user_name))
		strMain = Utility.BuildHtml(strMain, Model)
	End If
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub ShowStarterPage
	Dim strMain As String = Utility.ReadTextFile("starter.html")
	If Main.SESSIONS_ENABLED Then
		Dim user_name As String = Request.GetSession.GetAttribute2(Main.PREFIX & "username", "")
		Model.Put("user_name", Utility.DecodeURL(user_name))
		strMain = Utility.BuildHtml(strMain, Model)
	End If
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub PostRegister As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Register a new account
	' #Elements = ["register"]
	' #Body = {<br>&nbsp; "name": "name"<br>&nbsp; "email": "email",<br>&nbsp; "password": "password",<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_name As String = data.Get("name")
			Dim user_email As String = data.Get("email")
			Dim user_password As String = data.Get("password")
			
			If user_name = "" Or user_email = "" Or user_password = "" Then
				msg_text = "[Value Not Set]"
				Main.DB.WriteUserLog("account/register", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error JSON Input"
				Return HRM
			End If
			If Utility.Validate_Email(user_email) = False Then
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid Email Format"
				Return HRM
			End If
			strSQL = Main.DB.Queries.Get("SELECT_USER_DATA_BY_EMAIL")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
								
				Main.DB.WriteUserLog("account/register", "fail", msg_text, user_id)
				msg_text = "[Email Used] " & user_email

				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Email Used"
			Else
				Dim salt As String = Encryption.MD5(Rnd(100001, 999999))
				Dim hash As String = Encryption.MD5(user_password & salt)
				Dim code As String = Encryption.MD5(salt & user_email)
				Dim flag As String = "M"
				
				strSQL = Main.DB.Queries.Get("INSERT_NEW_USER")
				con.ExecNonQuery2(strSQL, Array As String(user_email, user_name, hash, salt, code, flag))
				
				strSQL = Main.DB.Queries.Get("GET_LAST_INSERT_ID")
				Dim user_id As Int = con.ExecQuerySingleResult(strSQL)
				msg_text = "[New User] " & user_email
				
				strSQL = Main.DB.Queries.Get("SELECT_USER_DATA_BY_ID")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_id))
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
					'Select Main.AUTHENTICATION_TYPE.ToUpperCase
					'	Case "JSON WEB TOKEN AUTHENTICATION"
					'		' Get Refresh Token LifeTime
					'		Dim AccessTokenLifeTime As Long = 60000 					' 1 minute
					'		Dim RefreshTokenLifeTime As Long = ReadRefreshTokenLifeTime
					'		If RefreshTokenLifeTime = 0 Then
					'			HRM.ResponseCode = 401
					'			HRM.ResponseError = "Invalid Client Credentials"
					'			Return HRM								
					'		End If
					'		
					'		' Unless client is mobile
					'		' We don't generate the tokens during registration
					'		Dim user_flag As String = Map2.Get("user_activation_flag")
					'		Main.JAT.Claims = CreateMap("client_id": Main.AUTH.CLIENT_ID, "user": user_name, "flag": user_flag, "token": "access", "iat": DateTime.Now, "exp": DateTime.Now + AccessTokenLifeTime)
					'		Main.JAT.ExpiresAt = DateTime.Now + AccessTokenLifeTime
					'		Main.JAT.Sign
					'		Dim access_token As String = Main.JAT.Token
					'		
					'		' Create a Refresh Token
					'		Main.JRT.Claims = CreateMap("client_id": Main.AUTH.CLIENT_ID, "user": user_name, "token": "refresh")
					'		Main.JRT.ExpiresAt = DateTime.Now + RefreshTokenLifeTime
					'		Main.JRT.Sign
					'		Dim refresh_token As String = Main.JRT.Token
					'	
					'		' Send refresh token to client as HttpOnly cookie
					'		' Disable this now. We ask user during login
					'		'Utility.ReturnCookie(Main.PREFIX & "refresh_token", refresh_token, DateTime.Now + 180000, True, Response)
					'		
					'		'Map2.Put("access_token", access_token)
					'		'Map2.Put("refresh_token", refresh_token)
					'		'Map2.Put("token_type", "bearer")
					'		'Map2.Put("expires_in", AccessTokenLifeTime) ' in ticks / milliseconds
					'End Select
					List1.Add(Map2)
				Loop
				
				' Send email
				SendEmail(user_name, user_email, code)
				Main.DB.WriteUserLog("account/register", "success", msg_text, user_id)
				
				HRM.ResponseCode = 201
				HRM.ResponseMessage = "Your Account Has Been Registered"
				HRM.ResponseData = List1
			End If
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error JSON Input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub GetActivate (code As String)
	#region Documentation
	' #Version = v2
	' #Desc = Activate account by activation code (usually from email)
	' #Elements = ["activate", ":code"]
	' #DefaultFormat = raw
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Dim Format As String = Request.GetParameter("format")
	Try
		'Log(code)
		strSQL = Main.DB.Queries.Get("SELECT_USER_EMAIL_BY_ACTIVATION_CODE")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(code))
		If res.NextRow Then
			Dim user_id As Int = res.GetInt("user_id")
			Dim user_email As String = res.GetString("user_email")
			Dim activation_code As String = Encryption.MD5(Rnd(100001, 999999))
			
			strSQL = Main.DB.Queries.Get("UPDATE_USER_FLAG_BY_EMAIL_AND_ACTIVATION_CODE")
			con.ExecNonQuery2(strSQL, Array As String("R", activation_code, user_email, code))
			
			msg_text = "[User Activated] " & user_email
			Main.DB.WriteUserLog("account/activate", "success", msg_text, user_id)
			
			If Format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "Activation Success"
			Else ' raw
				HRT.ResponseBody = $"<h1>Activation Success</h1><p>You can now login to the app</p>"$
			End If
		Else
			If Format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 404
				HRM.ResponseError = "Invalid Activation Code"
			Else ' raw
				HRT.ResponseBody = $"<h1>Invalid Activation Code</h1><p>Please refer to documentation</p>"$
			End If
		End If
	Catch
		LogError(LastException.Message)
		If Format.EqualsIgnoreCase("json") Then
			HRM.ResponseCode = 422
			HRM.ResponseError = "Error Execute Query"
		Else ' raw
			HRT.ResponseBody = $"<h1>Error Execute Query</h1><p>Please report to the developer</p>"$
		End If
	End Try
	Main.DB.CloseDB(con)
	'Return strMain
	If Format.EqualsIgnoreCase("json") Then
		Utility.ReturnHttpResponse(HRM, Response)
	Else ' raw
		Utility.ReturnHtmlBody(HRT, Response)
	End If
End Sub

Public Sub PostLogin As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Login using email and password to return basic user profile and access token
	' #Elements = ["login"]
	' #Body = {<br>&nbsp; "email": "email",<br>&nbsp; "password": "password"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Try
		If Main.SESSIONS_ENABLED Then
			' csrf_token generated in ShowLoginPage sub
			' Not sure this is a correct way to verify csrf-token
			If Utility.ValidateCsrfToken(Main.PREFIX & "csrf_token", "x-csrf-token", Request) = False Then
				msg_text = "[Invalid csrf-token detected]"
				Main.DB.WriteUserLog("account/login", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "CSRF token mismatched"
				Return HRM
			End If
		End If
		
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")
			'Dim grant_type As String = data.Get("grant_type")
		
			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				Main.DB.WriteUserLog("account/login", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Credential Not Provided"
				Return HRM
			End If
		
			Dim DB As MiniORM
			DB.Initialize(con)
			DB.Table = "tbl_users"
			
			DB.Select = Array("user_salt")
			DB.Where = Array("user_email = ?")
			DB.Parameters = Array(email)
			Dim user_salt As String = DB.Scalar
			Dim user_hash As String = Encryption.MD5(password & user_salt)
			'Log(user_salt)
			'Log(user_hash)

			DB.Reset
			'DB.Select = Array("id AS user_id", "user_name", "IFNULL(user_token, '') AS user_token", "user_activation_flag")
			DB.Select = Array("id AS user_id", "user_name", "user_email", "user_activation_flag")
			DB.Where = Array("user_email = ?", "user_hash = ?")
			DB.Parameters = Array(email, user_hash)
			DB.Query
			'DB.OrderBy(Null, "")
			'For Each Row() As Object In DB.DBResult.Rows
			'	Log( Row )
			'	For Each R() As Object In Row
			'		Log( R )
			'	Next
			'Next
			If DB.DBTable.Count = 0 Then
				msg_text = "[Email or Password Not Match] " & email & "|" & password
				Main.DB.WriteUserLog("account/login", "fail", msg_text, 0)
				'Utility.ReturnError("Error Email Used", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 404
				HRM.ResponseError = "Email or Password Not Match"
				Return HRM
			End If
		
			Dim account As Map = DB.DBTable.First
			Dim user_id As Int = account.Get("user_id")
			Dim user_name As String = account.Get("user_name")
			Dim user_email As String = account.Get("user_email")
			Dim user_flag As String = account.Get("user_activation_flag")
			If user_flag = "M" Then
				msg_text = "[Not Activated] " & email
				Main.DB.WriteUserLog("account/login", "fail", msg_text, user_id)
				Main.DB.CloseDB(con)
				'Utility.ReturnError("Error Not Activated", 400, Response)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Not Activated"
				Return HRM
			End If
				
			Dim List1 As List
			List1.Initialize
			
			Dim Map2 As Map
			Map2.Initialize
			'Map2.Put("user_id", user_id)
			Map2.Put("client_id", Main.AUTH.CLIENT_ID)
			Map2.Put("user_name", user_name)
				
			Dim sessionId As String = Encryption.RandomHash2
			
			Select Main.AUTHENTICATION_TYPE.ToUpperCase
				Case "JSON WEB TOKEN AUTHENTICATION"
					' Get Refresh Token LifeTime
					Dim AccessTokenLifeTime As Long = 5 * 60000 ' 5 minutes
					Dim RefreshTokenLifeTime As Long = ReadRefreshTokenLifeTime
					If RefreshTokenLifeTime = 0 Then
						HRM.ResponseCode = 401
						HRM.ResponseError = "Invalid Client Credentials"
						Return HRM
					Else
						Log($"ReadRefreshTokenLifeTime = ${ReadRefreshTokenLifeTime/(1000*60)} minutes"$)
					End If
					
					'Main.JAT.Claims = CreateMap("user": user_name, "user_email": user_email, "client_id": Main.AUTH.CLIENT_ID, "flag": user_flag, "token": "access", "iat": DateTime.Now, "exp": DateTime.Now + AccessTokenLifeTime)
					Main.JAT.Claims = CreateMap("user_name": user_name, "user_email": user_email, "client_id": Main.AUTH.CLIENT_ID, "flag": user_flag, "token": "access")
					Main.JAT.IssuedAt = DateTime.Now
					Main.JAT.ExpiresAt = DateTime.Now + AccessTokenLifeTime
					Main.JAT.Sign
					Dim access_token As String = Main.JAT.Token
				
					' verify token
'					Main.JAT.Verify
'					Log( Main.JAT.Claims )
'					Log( Main.JAT.ExpiresAt )
'					Dim original_dateformat As String = DateTime.DateFormat
'					DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
'					Log( "iat:" & DateTime.Date( Main.JAT.ReadClaim("iat") * 1000 ) )
'					Log( "exp:" & DateTime.Date( Main.JAT.ReadClaim("exp") * 1000 ) )
'					DateTime.DateFormat = original_dateformat
'					Log( Main.JAT.ReadClaim("iss") )
				
					' Create a Refresh Token (without claim?)
					Main.JRT.Claims = CreateMap("user_name": user_name, "user_email": user_email, "client_id": Main.AUTH.CLIENT_ID, "token": "refresh")
					Main.JRT.IssuedAt = DateTime.Now
					Main.JRT.ExpiresAt = DateTime.Now + RefreshTokenLifeTime
					Dim original_dateformat As String = DateTime.DateFormat
					DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
					Log( "Refresh Token Expires at: " & DateTime.Date(DateTime.Now + RefreshTokenLifeTime) )
					DateTime.DateFormat = original_dateformat
					Main.JRT.Sign
					Dim refresh_token As String = Main.JRT.Token
						
					' Test
					Main.JAT.Verify
					If Main.JAT.Verified Then
						Log( $"${Main.JAT.ReadClaim("user_name")} : ${DateTime.Date(Main.JAT.ReadClaim("exp") * 1000)} : ${Main.JAT.ReadClaim("token")}"$ )
					End If
					Main.JRT.Verify
					If Main.JRT.Verified Then
						Log( $"${Main.JRT.ReadClaim("user_name")} : ${DateTime.Date(Main.JRT.ReadClaim("exp") * 1000)} : ${Main.JRT.ReadClaim("token")}"$ )
					End If					
					
					' Send refresh token to client as HttpOnly cookie
					If Main.COOKIES_ENABLED Then
						Utility.ReturnCookie(Main.PREFIX & "refresh_token", refresh_token, DateTime.Now + RefreshTokenLifeTime, True, Response)
					Else
						Map2.Put("refresh_token", refresh_token)
					End If

					' Return the newly created token as map data
					Map2.Put("access_token", access_token)
					'Map2.Put("refresh_token", refresh_token)	' <-- will not send to client as json
					Map2.Put("token_type", "bearer")
					'Map2.Put("authenticated", True)
					Map2.Put("expires_in", AccessTokenLifeTime) ' in ticks / milliseconds
					'Dim original_dateformat As String = DateTime.DateFormat
					'DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
					'Map2.Put("issue_at", DateTime.Date(DateTime.Now))
					'Map2.Put("issue_at", Main.JAT.ReadClaim("iat"))
					'Log(Main.JAT.IssuedAt)
					'Map2.Put("issue_at", Main.JAT.IssuedAt)
					'Map2.Put("expire_at", DateTime.Date(DateTime.Now + AccessTokenLifeTime)	)
					'Map2.Put("expire_at", DateTime.Date(Main.JAT.ReadClaim("exp")))
					'Log(Main.JAT.ExpiresAt)
					'Map2.Put("expire_at", DateTime.Date(Main.JAT.ExpiredAt))
					'DateTime.DateFormat = original_dateformat
					List1.Add(Map2)
				Case "TOKEN AUTHENTICATION"
					Dim RefreshTokenLifeTime As Long = ReadRefreshTokenLifeTime
					If RefreshTokenLifeTime = 0 Then
						HRM.ResponseCode = 401
						HRM.ResponseError = "Invalid Client Credentials"
						Return HRM
					End If

					Dim DB3 As MiniORM
					DB3.Initialize(con)
					
					DB3.Table = "RefreshToken"
					'DB3.Select = Array("ProtectedTicket")
					DB3.Where = Array("ClientId = ?")
					DB3.Parameters = Array(Main.AUTH.CLIENT_ID)
					DB3.Query
											
					If DB3.DBTable.Count > 0 Then
						Dim Res As Map = DB3.DBTable.First
						'Dim Ticket As Map = Ser.ConvertBytesToObject(Res.Get("ProtectedTicket"))
						'Dim access_token As Map = DB3.DBTable.Data.Get(0)
						Map2.Put("access_token", Res.Get("ID"))
						Map2.Put("refresh_token", Res.Get("refresh_token"))
						Map2.Put("token_type", "bearer")
								
						Map2.Put("expires_in", Res.Get("ExpiredTime") - DateTime.Now)
						Map2.Put("issue_at", Res.Get("IssuedTime"))
						Map2.Put("expire_at", Res.Get("ExpiredTime"))
					Else
						Dim TokenAuth As TokenAuthFilter
						TokenAuth.Initialize
								
						' Hard code a role
						Dim Claims As List
						Claims.Initialize
						Claims.Add(CreateMap("role": "client"))
								
						Dim T1 As RefreshToken
						T1.Initialize
						T1.ID = TokenAuth.getHash(Encryption.RandomHash)
						T1.ClientID = Main.AUTH.CLIENT_ID
						T1.UserName = user_name
						T1.IssuedTime = DateTime.Now 							' Main.JRT.ReadClaim("iat")
						T1.ExpiredTime = DateTime.Now + RefreshTokenLifeTime 	' Main.JRT.ReadClaim("exp")
						T1.Claims = Claims
						Dim Ser As B4XSerializator
						T1.ProtectedTicket = Utility.Object2Json( Ser.ConvertObjectToBytes(T1) )
						TokenAuth.AddRefreshToken(T1)
						'Wait For (TA.AddRefreshToken(RT)) Complete (Success As Boolean)
						'Log( Success )
						'Map2.Put("access_token", "")
								
						' Return the newly created token as map data
						Map2.Put("access_token", T1.ID)
						Map2.Put("refresh_token", Utility.GUID)
						Map2.Put("token_type", "bearer")
						Map2.Put("expires_in", T1.ExpiredTime - DateTime.Now) ' in ticks / milliseconds
						Dim original_dateformat As String = DateTime.DateFormat
						DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
						Map2.Put("issue_at", DateTime.Date(T1.IssuedTime))
						Map2.Put("expire_at", DateTime.Date(T1.ExpiredTime)	)
						DateTime.DateFormat = original_dateformat
					End If
					List1.Add(Map2)

				Case Else

			End Select
			
			' Store server session variables
			If Main.SESSIONS_ENABLED Then
				'user_name = Utility.EncodeURL(user_name)
				Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
				Request.GetSession.SetAttribute(Main.PREFIX & "username", user_name)
				Request.GetSession.SetAttribute(Main.PREFIX & "sessionId", sessionId)
				'Request.GetSession.SetAttribute(Main.PREFIX & "authenticated", True)
			End If

			' Treat client with cookies
			If Main.COOKIES_ENABLED Then
				user_name = Utility.EncodeURL(user_name)
				Utility.ReturnCookie(Main.PREFIX & "user_id", user_id, Main.COOKIES_EXPIRATION, False, Response)
				Utility.ReturnCookie(Main.PREFIX & "username", user_name, Main.COOKIES_EXPIRATION, False, Response)
				Utility.ReturnCookie(Main.PREFIX & "sessionId", sessionId, Main.COOKIES_EXPIRATION, False, Response)
				'Utility.ReturnCookie(Main.PREFIX & "authenticated", True, Main.COOKIES_EXPIRATION, False, Response)
			End If
			
			HRM.ResponseCode = 200
			HRM.ResponseMessage = "Successful Login"
			HRM.ResponseData = List1
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error Invalid Input"
		End If
	Catch
		LogError(LastException.Message)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

' Get access token using refresh token from cookie
Public Sub GetToken As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Get new access token using refresh_token from cookie
	' #Elements = ["token"]
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Try
		'Dim Refresh_Token As String
		Dim AccessTokenLifeTime As Long = 5 * 60000 ' 5 minutes
		Dim Refresh_Token As String
		'Dim Refresh_Token As String = Utility.RequestBearerToken(Request)
		'Log( Refresh_Token )
		Dim Cookie() As Cookie = Request.GetCookies
		For Each DeliciousCookie As Cookie In Cookie
			'Log(DeliciousCookie)
			Log(DeliciousCookie.Name & " : " & DeliciousCookie.Value)
			If DeliciousCookie.Name = Main.PREFIX & "refresh_token" Then
				Refresh_Token = DeliciousCookie.Value
				Log("[Cookie] refresh_token: " & Refresh_Token)
			End If
		Next
		
		Main.JRT.Token = Refresh_Token
		'Main.JRT.Issuer = Main.ROOT_URL
		Main.JRT.Verify
		If Main.JRT.Verified Then
			Dim Claims As Map = Main.JRT.Claims
			If Claims.IsInitialized Then
				'Dim user_id As Int = Claims.Get("user_id")
				Dim user_name As String = Claims.Get("user_name")
				Dim user_email As String = Claims.Get("user_email")
				Dim user_flag As String = Claims.Get("flag")
				Log($"user_name: ${user_name}"$)
				user_name = user_name.Replace("""", "")
				Main.JAT.Claims = CreateMap("user_name": user_name, "user_email": user_email, "client_id": Main.AUTH.CLIENT_ID, "flag": user_flag)
			End If
			Main.JAT.IssuedAt = DateTime.Now
			Main.JAT.ExpiresAt = DateTime.Now + AccessTokenLifeTime
			Main.JAT.Sign
			
			' Test
			Main.JAT.Verify
			If Main.JAT.Verified Then
				Dim original_dateformat As String = DateTime.DateFormat
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Log( $"${Main.JAT.ReadClaim("user_name")} : ${DateTime.Date(Main.JAT.ReadClaim("exp") * 1000)} : ${Main.JAT.ReadClaim("flag")}"$ )
				DateTime.DateFormat = original_dateformat
			End If

						
			Dim Map2 As Map
			Map2.Initialize
			'Map2.Put("user_id", user_id)
			Map2.Put("client_id", Main.AUTH.CLIENT_ID)
			Map2.Put("user_name", user_name)
			Map2.Put("token_type", "bearer")
			' Return the newly created token as map data
			Map2.Put("access_token", Main.JAT.Token)
			'Map2.Put("refresh_token", refresh_token)
			Map2.Put("token_type", "bearer")
			'Map2.Put("authenticated", True)
			Map2.Put("expires_at", DateTime.Now + AccessTokenLifeTime) ' in ticks / milliseconds
				
			Dim List1 As List
			List1.Initialize
			List1.Add(Map2)
			HRM.ResponseCode = 200
			HRM.ResponseMessage = "New Token Generated"
			HRM.ResponseData = List1
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = Main.JRT.Error
		End If
	Catch
		LogError(LastException)
		'Utility.ReturnErrorExecuteQuery(Response)
		HRM.ResponseCode = 500
		HRM.ResponseError = LastException.Message
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

' Get access token using refresh token from json
Public Sub PostToken As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Get access token from JSON
	' #Elements = ["token"]
	' #Body = {<br>&nbsp; "refresh_token": "refresh_token"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	'Dim msg_text As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim refresh_token As String = data.Get("refresh_token")

			If refresh_token = "" Then
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Credential Not Provided"
				Return HRM
			End If
			
			Dim JWT As JSONWebToken
			JWT.Initialize("HMAC256", Main.Secret.Refresh_Token, False)
			JWT.Issuer = Main.ROOT_URL
			JWT.Token = refresh_token
			JWT.Verify
			Dim Claims As Map
			If JWT.Claims.IsInitialized Then
				Claims = JWT.Claims
				
				'Dim user_id As Int = Claims.Get("user_id")
				Dim user_name As String = Claims.Get("user_name")
				Dim user_email As String = Claims.Get("user_email")
				Dim user_flag As String = Claims.Get("user_activation_flag")
				Dim AccessTokenLifeTime As Long = 5 * 60000 ' 5 minutes
				
				Main.JAT.Claims = CreateMap("user": user_name, "user_email": user_email, "client_id": Main.AUTH.CLIENT_ID, "flag": user_flag, "token": "access")
				Main.JAT.IssuedAt = DateTime.Now
				Main.JAT.ExpiresAt = DateTime.Now + AccessTokenLifeTime
				Main.JAT.Sign
				
				Dim Map2 As Map
				Map2.Initialize
				'Map2.Put("user_id", user_id)
				Map2.Put("client_id", Main.AUTH.CLIENT_ID)
				Map2.Put("user_name", user_name)
				Map2.Put("token_type", "bearer")
				' Return the newly created token as map data
				Map2.Put("access_token", Main.JAT.Token)
				'Map2.Put("refresh_token", refresh_token)
				Map2.Put("token_type", "bearer")
				'Map2.Put("authenticated", True)
				Map2.Put("expires_in", AccessTokenLifeTime) ' in ticks / milliseconds
				
				Dim List1 As List
				List1.Initialize
				List1.Add(Map2)
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "Successful Login"
				HRM.ResponseData = List1
			Else
				If JWT.Error.Contains("com.auth0.jwt.exceptions.TokenExpiredException") Then
					Claims = CreateMap("error": "Token Expired")
					Dim List1 As List
					List1.Initialize
					List1.Add(Map2)
					HRM.ResponseData = List1
				End If
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid Token"
			End If
		Else
			'Utility.ReturnErrorInvalidInput(Response)
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error Invalid Input"
		End If
	Catch
		LogError(LastException)
		Utility.ReturnErrorExecuteQuery(Response)
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

' Get user profile using access token
Public Sub GetAccount As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Get user profile using access token from header (localstorage)
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Try
		Dim List1 As List
		List1.Initialize
		
		Dim Client As Map = ReadClaimsFromHeader
		If Not(Client.IsInitialized) Then
			HRM.ResponseCode = 400
			HRM.ResponseError = "Bad Request"
			'HRM.ResponseData = List1
			Return HRM
		End If

		If Client.Size < 2 Then
			Dim client_error As String = Client.Get("error")
			If client_error.Length > 0 Then
				List1.Add(Client)
				HRM.ResponseCode = 400
				HRM.ResponseError = client_error
				HRM.ResponseData = List1
				Return HRM
			End If
		End If
		Dim user_email As String = Client.Get("user_email")
		user_email = user_email.Replace($"""$, "")
		
		Dim DB As MiniORM
		DB.Initialize(con)
		DB.Table = "tbl_users"
		DB.Select = Array("id AS user_id", "user_name", "user_email", "user_location", "user_activation_flag")
		DB.Where = Array("user_email = ?")
		DB.Parameters = Array(user_email)
		DB.Query

		If DB.DBTable.Count = 0 Then
			msg_text = "[Account Not Found]"
			Main.DB.WriteUserLog("account", "fail", msg_text, 0)
			Main.DB.CloseDB(con)
			HRM.ResponseCode = 404
			HRM.ResponseError = "Account Not Found"
			Return HRM
		End If
		
		Dim account As Map = DB.DBTable.First
		'Dim user_id As Int = account.Get("user_id")
		Dim user_name As String = account.Get("user_name")
		Dim user_location As String = account.Get("user_location") ' testing
		Dim user_flag As String = account.Get("user_activation_flag")
'		If user_flag = "M" Then
'			msg_text = "[Not Activated]"
'			Main.DB.WriteUserLog("account", "fail", msg_text, user_id)
'			Main.DB.CloseDB(con)
'			'Utility.ReturnError("Error Not Activated", 400, Response)
'			HRM.ResponseCode = 400
'			HRM.ResponseError = "Error Not Activated"
'			Return HRM
'		End If
			
		Dim Map2 As Map
		Map2.Initialize
		'Map2.Put("user_id", user_id)
		Map2.Put("client_id", Main.AUTH.CLIENT_ID)
		Map2.Put("user_name", user_name)
		Map2.Put("user_flag", user_flag)
		Map2.Put("user_location", user_location) ' testing
		Dim original_dateformat As String = DateTime.DateFormat
		DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
		Map2.Put("token_expires", DateTime.Date(Client.Get("exp") * 1000))
		DateTime.DateFormat = original_dateformat
	
		List1.Add(Map2)
		HRM.ResponseCode = 200
		HRM.ResponseData = List1
	Catch
		Log(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Return HRM
End Sub

' Verify and Retrieve Claims from Access Token
Private Sub ReadClaimsFromHeader As Map
	Dim Claims As Map
	Try
		Dim Token As String = Utility.RequestBearerToken(Request)
		Dim JWT As JSONWebToken
		JWT.Initialize("HMAC256", Main.Secret.Access_Token, False)
		JWT.Issuer = Main.ROOT_URL
		JWT.Token = Token
		JWT.Verify
		If JWT.Claims.IsInitialized Then
			Claims = JWT.Claims
		Else
			If JWT.Error.Contains("com.auth0.jwt.exceptions.TokenExpiredException") Then
				Claims = CreateMap("error": "Token Expired")
			End If
		End If
	Catch
		Log(LastException.Message)
		Claims = CreateMap("error": LastException.Message)
	End Try
	Return Claims
End Sub

Public Sub SessionLogin As Boolean
	Dim con As SQL = Main.DB.GetConnection
	Dim cookie_expiration As Long = 90 * 24 * 60 * 60 			' 90 days
	Dim msg_text As String
	Dim ses_text As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")
			Dim remember As String = data.Get("remember")
			
			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				ses_text = "Error Credential Not Provided"
				'Main.DB.WriteUserLog("account/login", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				Return False
			End If
		
			Dim DB As MiniORM
			DB.Initialize(con)
			DB.Table = "tbl_users"
			
			DB.Select = Array("user_salt")
			DB.Where = Array("user_email = ?")
			DB.Parameters = Array(email)
			Dim user_salt As String = DB.Scalar
			Dim user_hash As String = Encryption.MD5(password & user_salt)
			'Log(user_salt)
			'Log(user_hash)

			DB.Reset
			'DB.Select = Array("id AS user_id", "user_name", "IFNULL(user_token, '') AS user_token", "user_activation_flag")
			DB.Select = Array("id AS user_id", "user_name", "user_activation_flag")
			DB.Where = Array("user_email = ?", "user_hash = ?")
			DB.Parameters = Array(email, user_hash)
			DB.Query
			'DB.OrderBy(Null, "")
			'For Each Row() As Object In DB.DBResult.Rows
			'	Log( Row )
			'	For Each R() As Object In Row
			'		Log( R )
			'	Next
			'Next
			If DB.DBTable.Count = 0 Then
				msg_text = "[Email or Password Not Match] " & email & "|" & password
				ses_text = "Email or Password Not Match"
				Main.DB.WriteUserLog("account/login", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
				Return False
			End If
		
			Dim account As Map = DB.DBTable.First
			Dim user_id As Int = account.Get("user_id")
			Dim user_name As String = account.Get("user_name")
			Dim user_flag As String = account.Get("user_activation_flag")
			If user_flag = "M" Then
				msg_text = "[Not Activated] " & email
				ses_text = "Error Not Activated"
				Main.DB.WriteUserLog("account/login", "fail", msg_text, user_id)
				Main.DB.CloseDB(con)
				Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
				Return False
			End If
				
			Dim List1 As List
			List1.Initialize
			
			Dim Map2 As Map
			Map2.Initialize
			Map2.Put("user_id", user_id)
			'Map2.Put("client_id", Main.AUTH.CLIENT_ID)
			Map2.Put("user_name", user_name)

			user_name = Utility.EncodeURL(user_name)
	
			' Store server session variables
			Dim sessionId As String = Encryption.RandomHash2
				
			Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
			Request.GetSession.SetAttribute(Main.PREFIX & "username", user_name)
			Request.GetSession.SetAttribute(Main.PREFIX & "sessionId", sessionId)

			' Treat client with cookies
			If remember.ToLowerCase = "yes" Then
				If Main.COOKIES_ENABLED Then
					Utility.ReturnCookie(Main.PREFIX & "user_id", user_id, cookie_expiration, False, Response)
					Utility.ReturnCookie(Main.PREFIX & "username", user_name, cookie_expiration, False, Response)
					Utility.ReturnCookie(Main.PREFIX & "sessionId", sessionId, cookie_expiration, False, Response)
				End If
			End If
			
			Main.DB.CloseDB(con)
			Return True
		Else
			ses_text = "Error Invalid Input"
			Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
		End If
	Catch
		LogError(LastException.Message)
		ses_text = "Exception in Login"
		Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
	End Try
	Main.DB.CloseDB(con)
	Return False
End Sub

' Logout user session and remove cookie
Public Sub SessionLogout
	Dim Format As String = Request.GetParameter("format")
	
'	Select Main.AUTHENTICATION_TYPE.ToUpperCase
'		Case "JSON WEB TOKEN AUTHENTICATION"
'				
'		Case "TOKEN AUTHENTICATION"
'				
'		Case "BASIC AUTHENTICATION"
'			
'		Case Else
	'
'	End Select
	
	If Main.COOKIES_ENABLED Then
		Utility.ReturnCookie(Main.PREFIX & "refresh_token", "", 0, True, Response)
		Utility.ReturnCookie(Main.PREFIX & "user_id", "", 0, False, Response)
		Utility.ReturnCookie(Main.PREFIX & "username", "", 0, False, Response)
		Utility.ReturnCookie(Main.PREFIX & "sessionId", "", 0, False, Response)
		'Utility.ReturnCookie(Main.PREFIX & "authenticated", False, 0, False, Response)
		'Utility.ReturnLocation("/login", Response)
		
		Request.GetSession.Invalidate
	End If
	If Format.EqualsIgnoreCase("json") Then
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Logout Success"
		Utility.ReturnHttpResponse(HRM, Response)
	Else ' raw
		HRT.ResponseBody = $"<h1>Logout Success</h1><p>You can relogin again</p>"$
		Utility.ReturnHtmlBody(HRT, Response)
		'Utility.ReturnLocation(Main.ROOT_PATH & "login", Response)
		Utility.ReturnLocation(Main.ROOT_PATH, Response)
	End If
End Sub

Private Sub ReadRefreshTokenLifeTime As Long
	Dim con As SQL = Main.DB.GetConnection
	Dim TokenLifetime As Long
	Dim DB2 As MiniORM
	DB2.Initialize(con)
	DB2.Table = "ClientMaster"
	DB2.Where = Array("ClientId = ?", "ClientSecret = ?")
	DB2.Parameters = Array(Main.AUTH.CLIENT_ID, Main.AUTH.CLIENT_SECRET)
	DB2.Query
	If DB2.DBTable.Count > 0 Then
		Dim client As Map = DB2.DBTable.First
		TokenLifetime = client.Get("RefreshTokenLifeTime")
	End If
	Main.DB.CloseDB(con)
	Return TokenLifetime
End Sub

Private Sub SendEmail (user_name As String, user_email As String, activation_code As String)
	Dim smtp As SMTP
	Try
		Dim APP_TRADEMARK As String = Main.Config.Get("APP_TRADEMARK")
		Dim SMTP_USERNAME As String = Main.Config.Get("SMTP_USERNAME")
		Dim SMTP_PASSWORD As String = Main.Config.Get("SMTP_PASSWORD")
		Dim SMTP_SERVER As String = Main.Config.Get("SMTP_SERVER")
		Dim SMTP_USESSL As String = Main.Config.Get("SMTP_USESSL")
		Dim SMTP_PORT As Int = Main.Config.Get("SMTP_PORT")
		Dim ADMIN_EMAIL As String = Main.Config.Get("ADMIN_EMAIL")

		smtp.Initialize(SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, "SMTP")
		If SMTP_USESSL.ToUpperCase = "TRUE" Then smtp.UseSSL = True Else smtp.UseSSL = False
		smtp.HtmlBody = True
		LogDebug("Sending email...")
		smtp.Sender = SMTP_USERNAME
		smtp.To.Add(user_email)
		smtp.AuthMethod = smtp.AUTH_LOGIN
		smtp.subject = APP_TRADEMARK
		smtp.body = $"Hi ${user_name},<br />
		Please click on this link to finish the registration process:<br />
		<a href="${Main.ROOT_URL}${Main.ROOT_PATH}account/activate/${activation_code}" 
		id="activate-link" title="activate" target="_blank">${Main.ROOT_URL}${Main.ROOT_PATH}account/activate/${activation_code}</a><br />
		<br />
		If the link is not working, please copy the url to your browser.<br />
		<br />
		Regards,<br />
		<em>${APP_TRADEMARK}</em>"$	
		LogDebug(smtp.body)
		
		Dim sm As Object = smtp.Send
		Wait For (sm) SMTP_MessageSent (Success As Boolean)
		If Success Then
			LogDebug("Message sent successfully")
		Else
			LogDebug("Error sending message")
			LogDebug(LastException)
		End If
		
		'Notify site admin of new sign up
		smtp.Sender = SMTP_USERNAME
		smtp.To.Add(ADMIN_EMAIL)
		smtp.AuthMethod = smtp.AUTH_LOGIN
		smtp.HtmlBody = False
		smtp.subject = "New registration"
		smtp.body = $"Hi Admin,${CRLF}
		${user_name} has registered using our app."$
		
		Dim sm As Object = smtp.Send
		Wait For (sm) SMTP_MessageSent (Success As Boolean)
		If Success Then
			LogDebug("Message sent to Admin successfully")
		Else
			LogDebug("Error sending message to Admin")
			LogDebug(LastException)
		End If
	Catch
		LogDebug(LastException)
		Utility.ReturnError("Error-Send-Email", 400, Response)
	End Try
End Sub