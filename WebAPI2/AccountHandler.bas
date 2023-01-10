B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Account Handler class
' Version 2.02
' Additional Modules: Utility, MiniORM, JSONWebToken
' Additional Libraries: jNet, jServer, jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private HRT As HttpResponseContent
	Private Elements() As String
	Private Literals() As String = Array As String("", "account", "{action}", "{code}")
	Private Const FIRST_ELEMENT As Int = Main.Element.First
	Private Const SECOND_ELEMENT As Int = Main.Element.Second
	Private Const THIRD_ELEMENT As Int = Main.Element.Third
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Elements = Regex.Split("/", req.RequestURI)
	Dim SupportedMethods As List = Array As String("GET", "POST")
	If Utility.CheckAllowedVerb(SupportedMethods, Request.Method) = False Then
		Utility.ReturnMethodNotAllow(Response)
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
					Case THIRD_ELEMENT ' /account/:action/:code      <-- not tested
						Log( "THREE ELEMENTS" )
						If Elements(FIRST_ELEMENT) = Literals(1) Then 	' /account
							Select Elements(SECOND_ELEMENT)
								Case "activate" 						' /account/activate/:code
									Dim code As String = Elements(THIRD_ELEMENT)
									GetActivateUser(code)
									Return
							End Select
						End If
					Case SECOND_ELEMENT ' /account/:action
						Log( "TWO ELEMENTS" )
						If Elements(FIRST_ELEMENT) = Literals(1) Then ' /account
							Select Elements(SECOND_ELEMENT)
								Case "login"
									SessionLogin
									Return
								Case "logout" ' <-- tested
									SessionLogout
									Return
							End Select
						End If
					Case FIRST_ELEMENT
						Log( "ONE ELEMENTS" )
						If Elements(FIRST_ELEMENT) = Literals(1) Then ' /account							
							Log ( ElementLastIndex )
							' todo: Show Profile Page
							'ShowPage
						End If
					Case Else
						Log( "MORE THAN THREE ELEMENTS" )
						Log ( ElementLastIndex )
				End Select
			Case "POST"
				Select ElementLastIndex
					Case SECOND_ELEMENT ' /account/:action
						If Elements(FIRST_ELEMENT) = Literals(1) Then ' /account
							Select Elements(SECOND_ELEMENT)
								Case "register"
									Utility.ReturnResponse(PostRegisterAccount, Main.SimpleResponse, Main.SimpleResponseFormat, Response)
									Return
								Case "login" ' /account/login									
									Utility.ReturnResponse(PostLogin, Main.SimpleResponse, Main.SimpleResponseFormat, Response)
									Return									
							End Select
						End If
				End Select
		End Select
	Catch
		LogError(LastException.Message)
	End Try
	Utility.ReturnBadRequest(Response)
End Sub


Private Sub PostRegisterAccount As HttpResponseMessage
	#region Documentation
	' #Desc = Register a new account
	' #Elements = ["register"]
	' #Body = {<br>&nbsp; "eml": "email",<br>&nbsp; "pwd": "password",<br>&nbsp; "name": "name"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_email As String = data.Get("eml")
			Dim user_password As String = data.Get("pwd")
			Dim user_name As String = data.Get("name")
			If user_email = "" Or user_password = "" Or user_name = "" Then
				msg_text = "[Value Not Set]"
				Main.DB.WriteUserLog("user/register", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error JSON Input"
				Return HRM
			End If
			strSQL = Main.Queries.Get("SELECT_USER_DATA_BY_EMAIL")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
								
				Main.DB.WriteUserLog("user/register", "fail", msg_text, user_id)
				msg_text = "[Email Used] " & user_email

				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Email Used"
			Else
				Dim salt As String = Utility.MD5(Rnd(100001, 999999))
				Dim hash As String = Utility.MD5(user_password & salt)
				Dim code As String = Utility.MD5(salt & user_email)
				Dim key As String = Utility.SHA1(hash)
				Dim flag As String = "M"
				'Log("salt="&salt)
				'Log("hash="&hash)
				
				strSQL = Main.Queries.Get("INSERT_NEW_USER")
				con.ExecNonQuery2(strSQL, Array As String(user_email, user_name, hash, salt, key, code, flag))
				
				strSQL = Main.Queries.Get("GET_LAST_INSERT_ID")
				Dim user_id As Int = con.ExecQuerySingleResult(strSQL)
				msg_text = "[New User] " & user_email
				
				strSQL = Main.Queries.Get("SELECT_USER_DATA_BY_ID")
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
					List1.Add(Map2)
				Loop
				
				' Send email
				SendEmail(user_name, user_email, code)
				Main.DB.WriteUserLog("user/register", "success", msg_text, user_id)
				
				HRM.ResponseCode = 201
				HRM.ResponseMessage = "Created"
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

Private Sub GetActivateUser (code As String) 'As String
	#region Documentation
	' #Desc = Activate user by given activation code
	' #Elements = ["activate", ":code"]
	' #DefaultFormat = raw
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Dim Format As String = Request.GetParameter("format")
	Try
		Log(code)
		strSQL = Main.Queries.Get("SELECT_USER_EMAIL_BY_ACTIVATION_CODE")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(code))
		If res.NextRow Then
			Dim user_id As Int = res.GetInt("user_id")
			Dim user_email As String = res.GetString("user_email")
			Dim activation_code As String = Utility.MD5(Rnd(100001, 999999))
			
			strSQL = Main.Queries.Get("UPDATE_USER_FLAG_BY_EMAIL_AND_ACTIVATION_CODE")
			con.ExecNonQuery2(strSQL, Array As String("R", activation_code, user_email, code))
			
			msg_text = "[User Activated] " & user_email
			Main.DB.WriteUserLog("user/activate", "success", msg_text, user_id)
			
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

Private Sub PostLogin As HttpResponseMessage
	#region Documentation
	' #Desc = Login using email and password to return basic user profile and access token
	' #Elements = ["login"]
	' #Body = {<br>&nbsp; "email": "email",<br>&nbsp; "password": "password"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String

	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")
			'Dim grant_type As String = data.Get("grant_type")
		
			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, 0)
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
			Dim user_hash As String = Utility.MD5(password & user_salt)
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
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, 0)
				'Utility.ReturnError("Error Email Used", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 404
				HRM.ResponseError = "Email or Password Not Match"
				Return HRM
			End If
		
			Dim account As Map = DB.DBTable.First
			Dim user_id As Int = account.Get("user_id")
			Dim user_name As String = account.Get("user_name")
			Dim user_flag As String = account.Get("user_activation_flag")
			If user_flag = "M" Then
				msg_text = "[Not Activated] " & email
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, user_id)
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
			Map2.Put("client_id", Main.CLIENT_ID)
			Map2.Put("user_name", user_name)
			'Map2.Put("access_token", "n/a")
	
			user_name = Utility.EncodeURL(user_name)
			
			Select Main.AUTHENTICATION_TYPE.ToUpperCase
				Case "JSON WEB TOKEN AUTHENTICATION"
					' Get Refresh Token LifeTime
					Dim AccessTokenLifeTime As Long = 60000 ' 1 minute
					Dim RefreshTokenLifeTime As Long
					Dim DB2 As MiniORM
					DB2.Initialize(con)
					DB2.Table = "ClientMaster"
					'DB2.Select = Array("RefreshTokenLifeTime")
					DB2.Where = Array("ClientId = ?", "ClientSecret = ?")
					DB2.Parameters = Array(Main.CLIENT_ID, Main.CLIENT_SECRET)
					DB2.Query
					If DB2.DBTable.Count > 0 Then
						Dim client As Map = DB2.DBTable.First
						RefreshTokenLifeTime = client.Get("RefreshTokenLifeTime")
					Else
						HRM.ResponseCode = 401
						HRM.ResponseError = "Error Client Not Registered"
					End If
					
					Main.JAT.Claims = CreateMap("user": user_name, "flag": user_flag, "token": "access", "iat": DateTime.Now, "exp": DateTime.Now + AccessTokenLifeTime)
					'Main.JAT.IssuedAt = DateTime.Now + AccessTokenLifeTime
					Main.JAT.ExpiresAt = DateTime.Now + AccessTokenLifeTime
					'Log(Main.JAT.ExpiresAt)
					Main.JAT.Sign
					Dim access_token As String = Main.JAT.Token
					'Log(Main.JAT.ExpiresAt)
				
					' Create a Refresh Token (without claim?)
					Main.JRT.Claims = CreateMap("user": user_name, "flag": user_flag, "token": "refresh")
					'Main.JRT.ExpiresAt = DateTime.Now + 180000	' 3 minutes
					Main.JRT.ExpiresAt = DateTime.Now + RefreshTokenLifeTime
					Main.JRT.Sign
					Dim refresh_token As String = Main.JRT.Token
						
					' Send refresh token to client as HttpOnly cookie
					Utility.ReturnCookie(Main.PREFIX & "refresh_token", refresh_token, DateTime.Now + 180000, True, Response)

					' Return the newly created token as map data
					Map2.Put("access_token", access_token)
					'Map2.Put("refresh_token", refresh_token)	' <-- will not send to client as json
					Map2.Put("token_type", "bearer")
				
					Map2.Put("expires_in", AccessTokenLifeTime) ' in ticks / milliseconds
					Dim original_dateformat As String = DateTime.DateFormat
					DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
					'Map2.Put("issue_at", DateTime.Date(DateTime.Now))
					'Map2.Put("issue_at", Main.JAT.ReadClaim("iat"))
					'Log(Main.JAT.IssuedAt)
					'Map2.Put("issue_at", Main.JAT.IssuedAt)
					'Map2.Put("expire_at", DateTime.Date(DateTime.Now + AccessTokenLifeTime)	)
					'Map2.Put("expire_at", DateTime.Date(Main.JAT.ReadClaim("exp")))
					Log(Main.JAT.ExpiresAt)
					'Map2.Put("expire_at", DateTime.Date(Main.JAT.ExpiredAt))
					DateTime.DateFormat = original_dateformat
					List1.Add(Map2)
				Case "TOKEN AUTHENTICATION"
					Dim DB2 As MiniORM
					DB2.Initialize(con)
						
					Dim RefreshTokenLifeTime As Long
					DB2.Table = "ClientMaster"
					'DB2.Select = Array("RefreshTokenLifeTime")
					DB2.Where = Array("ClientId = ?", "ClientSecret = ?")
					DB2.Parameters = Array(Main.CLIENT_ID, Main.CLIENT_SECRET)
					DB2.Query
						
					If DB2.DBTable.Count > 0 Then
						Dim client As Map = DB2.DBTable.First
						RefreshTokenLifeTime = client.Get("RefreshTokenLifeTime")
							
						Dim DB3 As MiniORM
						DB3.Initialize(con)
					
						DB3.Table = "RefreshToken"
						'DB3.Select = Array("ProtectedTicket")
						DB3.Where = Array("UserName = ?", "ClientId = ?")
						DB3.Parameters = Array(user_name, Main.CLIENT_ID)
						DB3.Query
				
						Dim Ser As B4XSerializator
							
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
							T1.ID = TokenAuth.getHash(Utility.RandomString)
							T1.ClientID = Main.CLIENT_ID
							T1.UserName = user_name
							T1.IssuedTime = DateTime.Now 							' Main.JRT.ReadClaim("iat")
							T1.ExpiredTime = DateTime.Now + RefreshTokenLifeTime 	' Main.JRT.ReadClaim("exp")
							T1.Claims = Claims
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
					Else
						HRM.ResponseCode = 401
						HRM.ResponseError = "Error Client Not Registered"
					End If
				Case "BASIC AUTHENTICATION"
					Map2.Put("authenticated", True)
				Case Else
					Map2.Put("authenticated", True)
			End Select
			HRM.ResponseCode = 200
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

Private Sub SessionLogin As Boolean
	Dim con As SQL = Main.DB.GetConnection
	Dim cookie_expiration As Long = 90 * 24 * 60 * 60 			' in seconds
	Dim msg_text As String
	Dim ses_text As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")
			
			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				ses_text = "Error Credential Not Provided"
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
				'Request.GetSession.SetAttribute(Main.PREFIX & "authenticated", False)
				'Request.GetSession.Invalidate
				Return False
			End If
		
			Dim DB As MiniORM
			DB.Initialize(con)
			DB.Table = "tbl_users"
			
			DB.Select = Array("user_salt")
			DB.Where = Array("user_email = ?")
			DB.Parameters = Array(email)
			Dim user_salt As String = DB.Scalar
			Dim user_hash As String = Utility.MD5(password & user_salt)
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
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, 0)
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
				Main.DB.WriteUserLog("accounts/login", "fail", msg_text, user_id)
				Main.DB.CloseDB(con)
				Request.GetSession.SetAttribute(Main.PREFIX & "error", ses_text)
				Return False
			End If
				
			Dim List1 As List
			List1.Initialize
			
			Dim Map2 As Map
			Map2.Initialize
			Map2.Put("user_id", user_id)
			'Map2.Put("client_id", Main.CLIENT_ID)
			Map2.Put("user_name", user_name)

			user_name = Utility.EncodeURL(user_name)
	
			' Store server session variables
			Dim sessionId As String = Utility.SHA256(Utility.RandomString)
				
			Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
			Request.GetSession.SetAttribute(Main.PREFIX & "username", user_name)
			Request.GetSession.SetAttribute(Main.PREFIX & "sessionId", sessionId)
			Request.GetSession.SetAttribute(Main.PREFIX & "authenticated", True)

			' Treat client with cookies
			Utility.ReturnCookie(Main.PREFIX & "user_id", user_id, cookie_expiration, False, Response) ' 90 days
			Utility.ReturnCookie(Main.PREFIX & "username", user_name, cookie_expiration, False, Response) ' 90 days
			Utility.ReturnCookie(Main.PREFIX & "sessionId", sessionId, cookie_expiration, False, Response) ' 90 days
			Utility.ReturnCookie(Main.PREFIX & "authenticated", True, cookie_expiration, False, Response) ' 90 days
			
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

Private Sub SessionLogout
	#region Documentation
	' #Desc = Logout user session and remove cookie
	' #Elements = ["logout"]
	' #DefaultFormat = raw
	#End region
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
	
	If Main.SESSION_ENABLED Then
		Utility.ReturnCookie(Main.PREFIX & "refresh_token", "", 0, True, Response)
		Utility.ReturnCookie(Main.PREFIX & "user_id", "", 0, False, Response)
		Utility.ReturnCookie(Main.PREFIX & "username", "", 0, False, Response)
		Utility.ReturnCookie(Main.PREFIX & "sessionId", "", 0, False, Response)
		Utility.ReturnCookie(Main.PREFIX & "authenticated", False, 0, False, Response)
		'Utility.ReturnLocation(Main.API_PATH & "login", Response)
		
		Request.GetSession.Invalidate
	End If
	If Format.EqualsIgnoreCase("json") Then
		HRM.ResponseCode = 200
		HRM.ResponseMessage = "Logout Success"
		Utility.ReturnHttpResponse(HRM, Response)
	Else ' raw
		HRT.ResponseBody = $"<h1>Logout Success</h1><p>You can relogin again</p>"$
		Utility.ReturnHtmlBody(HRT, Response)
		Utility.ReturnLocation(Main.API_PATH & "login", Response)
	End If
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
		<a href="${Main.ROOT_URL}${Main.ROOT_PATH}user/activate/${activation_code}" 
		id="activate-link" title="activate" target="_blank">${Main.ROOT_URL}${Main.ROOT_PATH}user/activate/${activation_code}</a><br />
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