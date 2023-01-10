B4J=true
Group=Filters
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Token Authentication Filter class
' Version 0.01
' Additional Modules: Utility, MiniORM
' Additional Libraries: jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	'Private HRM As HttpResponseMessage
	Private DB As MiniORM
	Type RefreshToken (ID As String, UserName As String, ClientID As String, IssuedTime As Long, ExpiredTime As Long, Claims As List, ProtectedTicket As String)
End Sub

Public Sub Initialize
	DB.Initialize(Main.DB.GetConnection)
End Sub

'Return True to allow the request to proceed.
Public Sub Filter (req As ServletRequest, resp As ServletResponse) As Boolean
	Request = req
	Response = resp
	
	If Request.GetSession.GetAttribute2("authenticated", False) = True Then Return True
	Dim auths As List = Request.GetHeaders("Authorization")
	If auths.Size = 0 Then
		Response.SetHeader("WWW-Authenticate", $"Basic realm="Realm""$)
		'Response.SendError(401, "Authentication required")
		Utility.ReturnAuthorizationRequired(Response)
		Return False
	Else
		Dim Client As Map = Utility.RequestBasicAuth(Request)
		If CheckCredentials(Client.Get("CLIENT_ID"), Client.Get("CLIENT_SECRET")) Then
			Request.GetSession.SetAttribute("authenticated", True)
			'Utility.ReturnSuccess(Null, 200, Response)
			Return True
		Else
			'Response.SendError(401, "Authentication required")
			Utility.ReturnAuthorizationRequired(Response)
			Return False
		End If
	End If
End Sub

' Validate Client using ID and Secret
Public Sub CheckCredentials (ClientId As String, ClientSecret As String) As Boolean
	Dim success As Boolean
	DB.Table = "ClientMaster"
	DB.Where = Array("ClientID = ?", "ClientSecret = ?", "Active = 1")
	DB.Parameters = Array(ClientId, ClientSecret)
	DB.Query
	If DB.Count > 0 Then		
		Private ClientMaster As Map = DB.DBTable.First
		' Check is this Client = Active
		If 1 = ClientMaster.Get("Active") Then
			' Check Allowed Origin
			Dim AllowedOrigin As String = ClientMaster.Get("AllowedOrigin")
			If AllowedOrigin.Length > 0 And AllowedOrigin <> "*" Then
				If Request.FullRequestURI.ToLowerCase.StartsWith(AllowedOrigin.ToLowerCase) Then
					' Check Token Expiration
					
					
					If Main.CLIENT_ID.Length = 0 And Main.CLIENT_SECRET.Length = 0 Then
						Dim Client As Map = Utility.RequestBasicAuth(Request)
						Main.CLIENT_ID = Client.Get("CLIENT_ID")
						Main.CLIENT_SECRET = Client.Get("CLIENT_SECRET")
						' todo: temporary hard code
						Main.CLIENT_ID = "WebAPI200"
						Main.CLIENT_SECRET = "45D1CE22-650D-9A0E-6338-90C83BFB934F"
					End If

					Dim DB As MiniORM
					DB.Initialize(Main.DB.GetConnection)
					DB.Table = "ClientMaster"
					DB.Where = Array("ClientID = ?", "ClientSecret = ?", "Active = 1")
					DB.Parameters = Array(Main.CLIENT_ID, Main.CLIENT_SECRET)
					DB.Query
					If DB.Count > 0 Then
						success = True
					Else
						success = False
					End If
				Else
					success = False
				End If
			Else
				success = True
			End If
		Else
			success = False
		End If
		success = True
	End If
	Return success
End Sub

Public Sub AddRefreshToken (Token As RefreshToken) As ResumableSub ' Boolean
	Try
		DB.Table = "RefreshToken"
		DB.Where = Array("UserName = ?", "ClientID = ?")
		DB.Parameters = Array(Token.UserName, Token.ClientID)
	
		' Find existing token
		'Dim ExistingToken As RefreshToken = CreateRefreshToken(DB.First)
		'RemoveRefreshToken(ExistingToken)
		RemoveExistingToken(CreateRefreshToken(DB.First))
	
		DB.Reset
		'DB.DataColumn = Array("ID", "UserName", "ClientID", "IssuedTime", "ExpiredTime", "Claims", "ProtectedTicket")
		DB.DataColumn = Array("ID", "UserName", "ClientID", "IssuedTime", "ExpiredTime", "ProtectedTicket")
		'DB.Parameters = TokenToParameters(Token)
		' Modified Display Dates
		Dim original_dateformat As String = DateTime.DateFormat
		DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
		Dim Parameters As List = TokenToParameters(Token)
		Parameters.Set(3, DateTime.Date(Parameters.Get(3)))
		Parameters.Set(4, DateTime.Date(Parameters.Get(4)))
		DateTime.DateFormat = original_dateformat
		DB.Parameters = Parameters
		DB.Save
		
		Return True
	Catch
		Log(LastException)
		Return False
	End Try
End Sub

Public Sub FindRefreshToken (TokenID As String) As RefreshToken
	If TokenID = "" Then Return Null
	DB.Table = "RefreshToken"
	Dim row As Map = DB.Find(TokenID)
	Return CreateRefreshToken(row)
End Sub

Public Sub GetAllRefreshTokens As List
	DB.Table = "RefreshToken"
	Return DB.Results
End Sub

Private Sub RemoveExistingToken (Token As RefreshToken)
	If Not(Token.IsInitialized) Then Return
	DB.Table = "RefreshToken"
	DB.Where = Array("UserName = ?", "ClientID = ?")
	DB.Parameters = Array(Token.UserName, Token.ClientID)
	DB.Delete
End Sub

Public Sub RemoveRefreshToken (Token As RefreshToken)
	If Not(Token.IsInitialized) Then Return
	DB.Table = "RefreshToken"
	DB.Where = Array("UserName = ?", "ClientID = ?")
	DB.Parameters = Array(Token.UserName, Token.ClientID)
	DB.Delete
End Sub

Public Sub RemoveRefreshTokenByID (TokenID As String)
	If TokenID = "" Then Return
	DB.Table = "RefreshToken"
	DB.Where = Array("ID = ?")
	DB.Parameters = Array(TokenID)
	DB.Delete
End Sub

Public Sub CreateRefreshToken (row As Map) As RefreshToken
	Dim t1 As RefreshToken
	t1.Initialize
	If Not(row.IsInitialized) Then Return t1
	t1.UserName = row.Get("UserName")
	t1.ClientID = row.Get("ClientID")
	t1.IssuedTime = row.Get("IssuedTime")
	t1.ExpiredTime = row.Get("ExpiredTime")
	t1.ProtectedTicket = row.Get("ProtectedTicket")
	Return t1
End Sub

Private Sub TokenToParameters (Token As RefreshToken) As List
	Dim List1 As List
	List1.Initialize
	List1.Add(Token.ID)
	List1.Add(Token.UserName)
	List1.Add(Token.ClientID)
	List1.Add(Token.IssuedTime)
	List1.Add(Token.ExpiredTime)
	'List1.Add(Token.Claims)
	List1.Add(Token.ProtectedTicket)
	Return List1
End Sub

Public Sub getHash (input As String) As String
	Dim b() As Byte = Utility.SHA256(input).GetBytes("UTF8")
	'Dim su As StringUtils
	'Return su.EncodeBase64(b)
	Return Utility.EncodeBase64(b)
End Sub

'Public Sub GetBasicCredentials (auth As String) As String()
'	Dim Credentials() As String
'	If auth.StartsWith("Basic") Then
'		Dim b64 As String = auth.SubString("Basic ".Length)
'		Dim su As StringUtils
'		Dim b() As Byte = su.DecodeBase64(b64)
'		Dim raw As String = BytesToString(b, 0, b.Length, "utf8")
'		Credentials = Regex.Split(":", raw)
'	End If
'	Return Credentials
'End Sub

'Private Sub CheckCredentials (auth As String) As Boolean
'	Dim success As Boolean = False
'	If auth.StartsWith("Basic") Then
'		Dim b64 As String = auth.SubString("Basic ".Length)
'		Dim su As StringUtils
'		Dim b() As Byte = su.DecodeBase64(b64)
'		Dim raw As String = BytesToString(b, 0, b.Length, "utf8")
'		Dim UsernameAndPassword() As String = Regex.Split(":", raw)
'		If UsernameAndPassword.Length = 2 Then
'			'up to you to decide which credentials are allowed <---------------------------
'			'If UsernameAndPassword(0) = Main.Auth.User And UsernameAndPassword(1) = Main.Auth.Password Then
'			'
'			'End If
'		End If
'	End If
'	Return success
'End Sub

'Public Sub ValidateClient (ClientID As String, ClientSecret As String) As Object
'	DB.Table = "ClientMaster"
'	DB.Where = Array("ClientID = ?", "ClientSecret = ?")
'	DB.Parameters = Array(ClientID, ClientSecret)
'	Return DB.First
'End Sub