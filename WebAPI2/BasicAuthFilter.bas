B4J=true
Group=Filters
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Basic Authentication Filter class
' Version 0.02
' Additional Modules: DataConnector, Utility, MiniORM
' Additional Libraries: jSQL
' Source: https://www.b4x.com/android/forum/threads/jserver-authentication.79720/
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Type AUTH (CLIENT_ID As String, CLIENT_SECRET As String)
End Sub

Public Sub Initialize
	HRM.Initialize
End Sub

'Return True to allow the request to proceed.
Public Sub Filter (req As ServletRequest, resp As ServletResponse) As Boolean
	Request = req
	Response = resp
		
	Dim Auths As List = Request.GetHeaders("Authorization")
	Dim Client As Map = Utility.RequestBasicAuth(Auths)
	'Dim sf As Object = CheckCredentials(Client.Get("CLIENT_ID"), Client.Get("CLIENT_SECRET"))
	'Wait For (sf) Complete (Result As Boolean)
	'If Result Then
	If CheckCredentials(Client.Get("CLIENT_ID"), Client.Get("CLIENT_SECRET")) Then
		Return True
	End If
	
	Response.SetHeader("WWW-Authenticate", $"Basic realm="Realm""$)
	Utility.ReturnAuthorizationRequired(Response)
	Return False
End Sub

' Validate Client using ID and Secret
Private Sub CheckCredentials (ClientId As String, ClientSecret As String) As Boolean
	Dim success As Boolean
	Try
		If ClientId = "" Or ClientSecret = "" Then Return False
		
		Dim con As SQL = Main.DB.GetConnection
		Dim DB As MiniORM
		DB.Initialize(con)
		DB.Table = "ClientMaster"
		DB.Where = Array("ClientID = ?", "ClientSecret = ?", "Active = 1")
		DB.Parameters = Array(ClientId, ClientSecret)
		DB.Query
		'Main.DB.CloseDB(con)
		success = DB.Count > 0
	Catch
		Log(LastException)
	End Try
	Main.DB.CloseDB(con)
	Return success
End Sub