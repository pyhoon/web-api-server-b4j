B4J=true
Group=Filters
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' JSON Web Token Filter class
' Version 0.02
' Additional Modules: JSONWebToken, Utility, MiniORM
' Additional Libraries: jSQL
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
	
	Try
		Return ValidateToken
	Catch
		Log(LastException.Message)
		Utility.ReturnAuthorizationRequired(Response)
		Return False
	End Try
End Sub

' Validate Client using access token for Controllers
Public Sub ValidateToken As Boolean
	Try
		Dim AccessToken As String = Utility.RequestBearerToken(Request)
		Dim JWT As JSONWebToken
		JWT.Initialize("HMAC256", Main.Secret.Access_Token, False)
		JWT.Issuer = Main.ROOT_URL
		JWT.Token = AccessToken
		JWT.Verify
		If JWT.Verified Then
			Return True
		End If		
	Catch
		Log(LastException.Message)
	End Try
	Dim JWT_Error As String = JWT.Error
	If JWT_Error.Contains("com.auth0.jwt.exceptions.TokenExpiredException") Then
		Utility.ReturnTokenExpired(Response)
	Else
		Utility.ReturnError(JWT_Error, 400, Response)
	End If
	Return False
End Sub