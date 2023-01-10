B4J=true
Group=Filters
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Basic Authentication Filter class
' Version 0.02
' Additional Modules: Utility, MiniORM
' Additional Libraries: jSQL
' Source: https://www.b4x.com/android/forum/threads/jserver-authentication.79720/
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize
	HRM.Initialize
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
			Utility.ReturnAuthorizationRequired(Response)
			Return False
		End If
	End If
End Sub

' Validate Client using ID and Secret
Private Sub CheckCredentials (ClientId As String, ClientSecret As String) As Boolean
	Dim success As Boolean
	Dim DB As MiniORM
	DB.Initialize(Main.DB.GetConnection)
	DB.Table = "ClientMaster"
	DB.Where = Array("ClientID = ?", "ClientSecret = ?", "Active = 1")
	DB.Parameters = Array(ClientId, ClientSecret)
	DB.Query
	If DB.Count > 0 Then
		success = True
	End If
	Return success
End Sub