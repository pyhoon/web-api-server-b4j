B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Authentication Handler class
' Version 2.00
' Additional Modules: Utility, MiniORM, JSONWebToken
' Additional Libraries: jNet, jServer, jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private HRT As HttpResponseContent
	Private Elements() As String
	Private Literals() As String = Array As String("", "account", "{action}", "{code}")
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	HRM.Initialize
	
	Elements = Regex.Split("/", req.RequestURI)
	Dim SupportedMethods As List = Array As String("GET", "POST")
	If Utility.CheckAllowedVerb(SupportedMethods, Request.Method) = False Then
		Utility.ReturnMethodNotAllow(Response)
		Return
	End If
	
	ProcessRequest
End Sub

Private Sub ProcessRequest
	Try
		Select Request.Method.ToUpperCase
			Case "GET"
				Select Elements.Length - 1					
					Case Main.Element.Third ' /account/:action/:code
						If Elements(Main.Element.First) = Literals(1) Then
							Select Elements(Main.Element.Second)
								Case "activate"
									Dim code As String = Elements(Main.Element.Third)
									'Dim Format As String = Request.GetParameter("format")
									'Utility.ReturnHttpResponse(GetProduct(pid), Response)
									GetActivateUser(code)
									Return
							End Select

						End If
				End Select
			Case "POST"
				Select Elements.Length - 1
					Case Main.Element.Second ' /account/:action
						If Elements(Main.Element.First) = Literals(1) Then
							Select Elements(Main.Element.Second)
								Case "register"
									ReturnResponse(PostRegisterAccount)
									Return
								Case "authenticate" ' /account/authenticate
									ReturnResponse(PostAuthenticate)
									Return
								Case "refresh-token"
									ReturnResponse(PostRefreshToken)
									Return
							End Select
						End If
				End Select
		End Select
	Catch
		LogError(LastException.Message)
	End Try
	Dim Format As String = Request.GetParameter("format")
	If Format.EqualsIgnoreCase("json") Then
		Utility.ReturnBadRequest(Response)
	Else
		Dim strMessage As String = $"<h1>Bad Request</h1><p>Please refer to documentation</p>"$
		Utility.ReturnHTML(strMessage, Response)
	End If
End Sub

Private Sub ReturnResponse (Message As HttpResponseMessage)
	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(Message, Response)
	Else
		Utility.ReturnHttpResponse(Message, Response)
	End If
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

Private Sub PostAuthenticate As HttpResponseMessage
	#region Documentation
	' #Desc = Authenticate account with email and password to return basic user profile and access token
	' #Elements = ["authenticate"]
	' #Body = {<br>&nbsp; "email": "email",<br>&nbsp; "password": "password"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	'Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")

			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Credential Not Provided"
				Return HRM
			End If
			
			'strSQL = Main.Queries.Get("SELECT_USER_SALT_BY_EMAIL")
			'Dim user_salt As String = con.ExecQuerySingleResult2(strSQL, Array As String(user_email))
			
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
			DB.Select = Array("id AS user_id", "IFNULL(user_token, '') AS user_token", "user_activation_flag")
			'Dim Criteria1 As ORMFilter = DB.CreateORMFilter("user_email", "=", user_email)
			'Dim Criteria2 As ORMFilter = DB.CreateORMFilter("user_hash", "=", user_hash)
			'DB.Where(Array(Criteria1, Criteria2))
			DB.Where = Array("user_email = ?", "user_hash = ?")
			DB.Parameters = Array(email, user_hash)
			DB.Query
			
'			For Each Row() As Object In DB.DBResult.Rows
'				Log( Row )
'				For Each R() As Object In Row
'					Log( R )
'				Next
'			Next
			For i = 0 To DB.DBTable.Data.Size - 1
				Log( DB.DBTable.Data.Get( i ) )
				Dim account As Map = DB.DBTable.Data.Get( i )
				Dim user_id As Int = account.Get("user_id")
				If account.Get("user_activation_flag") = "M" Then
					msg_text = "[Not Activated] " & email
					Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, user_id)
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
						
				Dim user_token As String = account.Get("user_token")
				If user_token = "" Then
					' Use JWT
					If Main.JWT.IsInitialized Then
						CreateAndSignToken(Main.JWT)
						user_token = Main.JWT.Token
					Else
						user_token = Utility.SHA1(Rnd(100001, 999999))
					End If
					' Update token (optional)
					'strSQL = Main.Queries.Get("UPDATE_USER_TOKEN_BY_EMAIL_AND_APIKEY")
					'con.ExecNonQuery2(strSQL, Array As String(user_token, user_email, user_apikey))
					DB.DataColumn =Array("user_token") ' CreateMap("user_token": Null)
					DB.UpdateModifiedDate = True
					DB.Where = Array("user_email = ?")
					DB.Parameters = Array(user_token, email)
					DB.Save
							
					msg_text = $"[New token generated] ${user_token} (${email})"$
				Else
					msg_text = $"[User login with token] ${user_token} (${email})"$
				End If

				Map2.Put("token", user_token)
				' Set session variables
				Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
				Request.GetSession.SetAttribute(Main.PREFIX & "username", email)
				'Request.GetSession.SetAttribute(Main.PREFIX & "apikey", user_apikey)
				Request.GetSession.SetAttribute(Main.PREFIX & "token", user_token)

'				' Send token to client as cookie
				Dim deliciousCookie As Cookie
				deliciousCookie.Initialize(Main.PREFIX & "refresh-token", user_token)
				deliciousCookie.HttpOnly = True
				deliciousCookie.MaxAge = 15 * 60 ' seconds
				Response.AddCookie(deliciousCookie)
				
				List1.Add(Map2)

				Main.DB.WriteUserLog("accounts/authenticate", "success", msg_text, user_id)
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "User Token acquired"
				HRM.ResponseData = List1
			Next
			
			If DB.DBTable.Data.Size = 0 Then
				msg_text = "[Email or Password Not Match] " & email
				Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, 0)
				'Utility.ReturnError("Error Email Used", 400, Response)
				HRM.ResponseCode = 404
				HRM.ResponseError = "Email or Password Not Match"
			End If
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error Invalid Input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Private Sub PostRefreshToken As HttpResponseMessage
	#region Documentation
	' #Desc = Refresh access token using cookie
	' #Elements = ["refresh-token"]
	' #Body = {<br>&nbsp; "refresh-token": "refresh-token"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	'Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim email As String = data.Get("email")
			Dim password As String = data.Get("password")

			If email = "" Or password = "" Then
				msg_text = "[Email or Password Not Set]"
				Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Credential Not Provided"
				Return HRM
			End If
			
			'strSQL = Main.Queries.Get("SELECT_USER_SALT_BY_EMAIL")
			'Dim user_salt As String = con.ExecQuerySingleResult2(strSQL, Array As String(user_email))
			
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
			DB.Select = Array("id AS user_id", "IFNULL(user_token, '') AS user_token", "user_activation_flag")
			'Dim Criteria1 As ORMFilter = DB.CreateORMFilter("user_email", "=", user_email)
			'Dim Criteria2 As ORMFilter = DB.CreateORMFilter("user_hash", "=", user_hash)
			'DB.Where(Array(Criteria1, Criteria2))
			DB.Where = Array("user_email = ?", "user_hash = ?")
			DB.Parameters = Array(email, user_hash)
			DB.Query
			
'			For Each Row() As Object In DB.DBResult.Rows
'				Log( Row )
'				For Each R() As Object In Row
'					Log( R )
'				Next
'			Next
			For i = 0 To DB.DBTable.Data.Size - 1
				Log( DB.DBTable.Data.Get( i ) )
				Dim account As Map = DB.DBTable.Data.Get( i )
				Dim user_id As Int = account.Get("user_id")
				If account.Get("user_activation_flag") = "M" Then
					msg_text = "[Not Activated] " & email
					Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, user_id)
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
						
				Dim user_token As String = account.Get("user_token")
				If user_token = "" Then
					' Use JWT
					If Main.JWT.IsInitialized Then
						CreateAndSignToken(Main.JWT)
						user_token = Main.JWT.Token
					Else
						user_token = Utility.SHA1(Rnd(100001, 999999))
					End If
					' Update token (optional)
					'strSQL = Main.Queries.Get("UPDATE_USER_TOKEN_BY_EMAIL_AND_APIKEY")
					'con.ExecNonQuery2(strSQL, Array As String(user_token, user_email, user_apikey))
					DB.DataColumn = Array("user_token") ' CreateMap("user_token": Null)
					DB.UpdateModifiedDate = True
					DB.Where = Array("user_email = ?")
					DB.Parameters = Array(user_token, email)
					DB.Save
							
					msg_text = $"[New token generated] ${user_token} (${email})"$
				Else
					msg_text = $"[User login with token] ${user_token} (${email})"$
				End If

				Map2.Put("token", user_token)
				' Set session variables
				Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
				Request.GetSession.SetAttribute(Main.PREFIX & "username", email)
				'Request.GetSession.SetAttribute(Main.PREFIX & "apikey", user_apikey)
				Request.GetSession.SetAttribute(Main.PREFIX & "token", user_token)

'				' Send token to client as cookie
				Dim deliciousCookie As Cookie
				deliciousCookie.Initialize(Main.PREFIX & "refresh-token", user_token)
				deliciousCookie.HttpOnly = True
				deliciousCookie.MaxAge = 15 * 60 ' seconds
				Response.AddCookie(deliciousCookie)
				
				List1.Add(Map2)

				Main.DB.WriteUserLog("accounts/authenticate", "success", msg_text, user_id)
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "User Token acquired"
				HRM.ResponseData = List1
			Next
			
			If DB.DBTable.Data.Size = 0 Then
				msg_text = "[Email or Password Not Match] " & email
				Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, 0)
				'Utility.ReturnError("Error Email Used", 400, Response)
				HRM.ResponseCode = 404
				HRM.ResponseError = "Email or Password Not Match"
			End If
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error Invalid Input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Sub CreateAndSignToken (jwt As JSONWebToken)
	jwt.withIssuer("Computerise")
	jwt.withClaim(CreateMap("user": "Aeric", "isAdmin": True))
	jwt.withExpiresAt(DateTime.Now + 180000)
	jwt.Sign
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