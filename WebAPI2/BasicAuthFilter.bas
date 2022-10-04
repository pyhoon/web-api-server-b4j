B4J=true
Group=Filters
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Basic Authentication Filter class
' Source: https://www.b4x.com/android/forum/threads/jserver-authentication.79720/
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

'Return True to allow the request to proceed.
Public Sub Filter (req As ServletRequest, resp As ServletResponse) As Boolean
	If req.GetSession.GetAttribute2("logged in", False) = True Then Return True
	Dim auths As List = req.GetHeaders("Authorization")
	If auths.Size = 0 Then
		resp.SetHeader("WWW-Authenticate", $"Basic realm="Realm""$)
		resp.SendError(401, "authentication required")
		Return False
	Else
		If CheckCredentials(auths.Get(0)) Then
			req.GetSession.SetAttribute("logged in", True)
			Return True
		Else
			resp.SendError(401, "authentication required")
			Return False
		End If
	End If
End Sub

Private Sub CheckCredentials (auth As String) As Boolean
	Dim success As Boolean = False
	If auth.StartsWith("Basic") Then
		Dim b64 As String = auth.SubString("Basic ".Length)
		Dim su As StringUtils
		Dim b() As Byte = su.DecodeBase64(b64)
		Dim raw As String = BytesToString(b, 0, b.Length, "utf8")
		Dim UsernameAndPassword() As String = Regex.Split(":", raw)
		If UsernameAndPassword.Length = 2 Then
			'up to you to decide which credentials are allowed <---------------------------
			If UsernameAndPassword(0) = Main.Auth.User And UsernameAndPassword(1) = Main.Auth.Password Then
				success = True
			End If
		End If
	End If
	Return success
End Sub