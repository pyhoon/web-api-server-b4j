B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Authentication Handler class
' Version 2.02
' Additional Modules: Utility, MiniORM, JSONWebToken
' Additional Libraries: jNet, jServer, jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private Elements() As String
	'Private Literals() As String = Array As String("", "authenticate", "{action}", "{code}")
	Private Const FIRST_ELEMENT As Int = Main.Element.First
	'Private Const SECOND_ELEMENT As Int = Main.Element.Second
	'Private Const THIRD_ELEMENT As Int = Main.Element.Third
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Elements = Regex.Split("/", req.RequestURI)
	Dim SupportedMethods As List = Array As String("POST")
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
			Case "POST"
				Select ElementLastIndex
					'Case SECOND_ELEMENT ' /authenticate/:action
					'	If Elements(FIRST_ELEMENT) = Literals(1) Then ' /authenticate
					'		Select Elements(SECOND_ELEMENT)
					'			Case "authenticate" ' /authenticate
					'
					'		End Select
					'	End If
					Case FIRST_ELEMENT ' /authenticate or /token
						Select Elements(FIRST_ELEMENT)
							'Case "authenticate"
							'	'Utility.ReturnResponse(PostAuthenticate, Response) ' for token based authentication
							'	PostAuthenticate
							'	Return
							Case "token"
								'Utility.ReturnResponse(PostToken, Response)
								PostToken
								Return
							Case "refresh"
								'Utility.ReturnResponse(PostRefreshToken, Response)
								PostRefreshToken
								Return
						End Select
				End Select
		End Select
		Utility.ReturnBadRequest(Response)
	Catch
		LogError(LastException.Message)
	End Try
End Sub

Private Sub PostToken
	#region Documentation
	' #Desc = Get access token and refresh token
	' #Elements = ["token"]
	' #Body = {<br>&nbsp; "refresh_token": "refresh_token"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	'Dim msg_text As String
	'Dim blnExpired As Boolean
	'Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Select Main.AUTHENTICATION_TYPE.ToUpperCase
				Case "JSON WEB TOKEN AUTHENTICATION"
					' Validate with Token
					Dim access_token As String '= Request.GetSession.GetAttribute2(Main.PREFIX & "access_token", "") 'data.Get("access_token")
					'Dim user_id As String = ""
					Dim user_name As String = ""
					Dim user_flag As String = ""
					'Dim grant_type As String = data.Get("grant_type")
					Dim refresh_token As String
			
					If access_token <> "" Then
						' Use JWT
						If Main.JAT.IsInitialized Then
							' Check is token expired?
							Main.JAT.Token = access_token
							'If Main.JAT.Expired Then
							'	blnExpired = True
'							' Refresh Token
'							Dim RefreshToken As String = Request.GetSession.GetAttribute2(Main.PREFIX & "refresh_token", False)
'							If RefreshToken.Length > 0 Then
'								
'							Else
'								HRM.ResponseCode = 400
'								HRM.ResponseError = "Error Invalid Refresh Token"
'							End If
							'Else
							'	msg_text = $"[User login with token] ${access_token}"$
							'End If
						Else
							'msg_text = $"[User login with token] ${access_token}"$
						End If
					Else
						' Use JWT
						If Main.JAT.IsInitialized Then
							Main.JAT.Claims = CreateMap("user": user_name, "flag": user_flag, "token": "access")
							Main.JAT.ExpiresAt = DateTime.Now + 60000 ' 1 minute
							Main.JAT.Sign
							access_token = Main.JAT.Token
						
							' Create a Refresh Token (without claim?)
							Main.JRT.Claims = CreateMap("user": user_name, "flag": user_flag, "token": "refresh")
							Main.JRT.ExpiresAt = DateTime.Now + 180000	' 3 minutes
							Main.JRT.Sign
							refresh_token = Main.JRT.Token
							
							' Send refresh token to client as HttpOnly cookie
							'Utility.ReturnCookie(Main.PREFIX & "refresh_token", refresh_token, DateTime.Now + 180000, True, Response)
							
							' Test
							Log( $"${Main.JAT.ReadClaim("user")} : ${Main.JAT.ReadClaim("exp")} : ${Main.JAT.ReadClaim("token")}"$ )
							Log( $"${Main.JRT.ReadClaim("user")} : ${Main.JRT.ReadClaim("exp")} : ${Main.JRT.ReadClaim("token")}"$ )
						Else
							access_token = Utility.SHA1(Rnd(100001, 999999))
							refresh_token = Utility.SHA256(Rnd(100001, 999999))
						End If
						Dim ResponseData As List
						ResponseData.Initialize
						ResponseData.Add(CreateMap("access_token": access_token, "refresh_token": refresh_token))
						HRM.ResponseData = ResponseData
					End If
					
				Case "TOKEN AUTHENTICATION"
					
			End Select
		Else
			Utility.ReturnErrorInvalidInput(Response)
		End If
	Catch
		LogError(LastException)
		Utility.ReturnErrorExecuteQuery(Response)
	End Try
	Main.DB.CloseDB(con)
End Sub

Private Sub PostRefreshToken
	#region Documentation
	' #Desc = Refresh access token using cookie
	' #Elements = ["refresh"]
	' #Body = {<br>&nbsp; "refresh_token": "refresh_token"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	'Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			'Dim refresh_token As String = data.Get(Main.PREFIX & "refresh_token")
			Dim refresh_token As String = data.Get("refresh_token")

			If refresh_token = "" Then
				msg_text = "[Refresh Token Not Set]"
				Main.DB.WriteUserLog("accounts/refresh", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Utility.ReturnErrorCredentialNotProvided(Response)
			End If
			
			'strSQL = Main.Queries.Get("SELECT_USER_SALT_BY_EMAIL")
			'Dim user_salt As String = con.ExecQuerySingleResult2(strSQL, Array As String(user_email))
			
'			Dim DB As MiniORM
'			DB.Initialize(con)
'			DB.Table = "tbl_users"
'			
'			DB.Select = Array("user_salt")
'			DB.Where = Array("user_email = ?")
'			DB.Parameters = Array(email)
'			Dim user_salt As String = DB.Scalar
'			Dim user_hash As String = Utility.MD5(password & user_salt)
			'Log(user_salt)
			'Log(user_hash)

'			DB.Reset
'			DB.Select = Array("id AS user_id", "IFNULL(user_token, '') AS user_token", "user_activation_flag")
'			'Dim Criteria1 As ORMFilter = DB.CreateORMFilter("user_email", "=", user_email)
'			'Dim Criteria2 As ORMFilter = DB.CreateORMFilter("user_hash", "=", user_hash)
'			'DB.Where(Array(Criteria1, Criteria2))
'			DB.Where = Array("user_email = ?", "user_hash = ?")
'			DB.Parameters = Array(email, user_hash)
'			DB.Query
			
'			For Each Row() As Object In DB.DBResult.Rows
'				Log( Row )
'				For Each R() As Object In Row
'					Log( R )
'				Next
'			Next
'			For i = 0 To DB.DBTable.Data.Size - 1
'				Log( DB.DBTable.Data.Get( i ) )
'				Dim account As Map = DB.DBTable.Data.Get( i )
'				Dim user_id As Int = account.Get("user_id")
'				If account.Get("user_activation_flag") = "M" Then
'					msg_text = "[Not Activated] " & email
'					Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, user_id)
'					Main.DB.CloseDB(con)
'					'Utility.ReturnError("Error Not Activated", 400, Response)
'					HRM.ResponseCode = 400
'					HRM.ResponseError = "Error Not Activated"
'					Return HRM
'				End If
'				
'				Dim List1 As List
'				List1.Initialize
'			
'				Dim Map2 As Map
'				Map2.Initialize
'						
'				Dim user_token As String = account.Get("user_token")
'				If user_token = "" Then
'					' Use JWT
'					If Main.JWT.IsInitialized Then
'						CreateAndSignToken(Main.JWT)
'						user_token = Main.JWT.Token
'					Else
'						user_token = Utility.SHA1(Rnd(100001, 999999))
'					End If
'					' Update token (optional)
'					'strSQL = Main.Queries.Get("UPDATE_USER_TOKEN_BY_EMAIL_AND_APIKEY")
'					'con.ExecNonQuery2(strSQL, Array As String(user_token, user_email, user_apikey))
'					DB.DataColumn = Array("user_token") ' CreateMap("user_token": Null)
'					DB.UpdateModifiedDate = True
'					DB.Where = Array("user_email = ?")
'					DB.Parameters = Array(user_token, email)
'					DB.Save
'							
'					msg_text = $"[New token generated] ${user_token} (${email})"$
'				Else
'					msg_text = $"[User login with token] ${user_token} (${email})"$
'				End If
'
'				Map2.Put("token", user_token)
'				' Set session variables
'				Request.GetSession.SetAttribute(Main.PREFIX & "user_id", user_id)
'				Request.GetSession.SetAttribute(Main.PREFIX & "username", email)
'				'Request.GetSession.SetAttribute(Main.PREFIX & "apikey", user_apikey)
'				Request.GetSession.SetAttribute(Main.PREFIX & "token", user_token)
'
''				' Send token to client as cookie
'				Dim deliciousCookie As Cookie
'				deliciousCookie.Initialize(Main.PREFIX & "refresh_token", user_token)
'				deliciousCookie.HttpOnly = True
'				deliciousCookie.MaxAge = 15 * 60 ' seconds
'				Response.AddCookie(deliciousCookie)
'				
'				' Check Network tab, Cookies, check 'show filtered out request cookies'
'				
'				List1.Add(Map2)
'
'				Main.DB.WriteUserLog("accounts/authenticate", "success", msg_text, user_id)
'				HRM.ResponseCode = 200
'				HRM.ResponseMessage = "User Token acquired"
'				HRM.ResponseData = List1
'			Next
			
'			If DB.DBTable.Data.Size = 0 Then
'				msg_text = "[Email or Password Not Match] " & email
'				Main.DB.WriteUserLog("accounts/authenticate", "fail", msg_text, 0)
'				'Utility.ReturnError("Error Email Used", 400, Response)
'				HRM.ResponseCode = 404
'				HRM.ResponseError = "Email or Password Not Match"
'			End If
		Else
			Utility.ReturnErrorInvalidInput(Response)
		End If
	Catch
		LogError(LastException)
		Utility.ReturnErrorExecuteQuery(Response)
	End Try
	Main.DB.CloseDB(con)
End Sub