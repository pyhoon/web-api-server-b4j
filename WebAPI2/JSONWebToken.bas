B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' JSONWebToken class 
' todo: convert to filter class
' Version 2.00
'
' Stop using JWTs! https://gist.github.com/samsch/0d1f3d3b4745d778f78b230cf6061452
' YouTube https://www.youtube.com/watch?v=pYeekwv3vC4
Sub Class_Globals
	Private JWT As JavaObject
	Private ALG As JavaObject
	Private builder As JavaObject
	Private verifier As JavaObject
	'Private m_IssuedAt As String
	'Private m_Issuer As String
	'Private m_Claims As Map
	'Private m_ExpiresAt As Object
	Private m_Token As Object
	Private m_Initialized As Boolean
	Private m_Verified As Boolean
	'Private m_Expired As Boolean
	Private m_Exception As String
End Sub

Public Sub Initialize (Algorithm As String, Secret As String, Base64Encode As Boolean)
	Private SupportedAlgorithms As List = Array As String("HMAC256", "HMAC384", "HMAC512")
	If SupportedAlgorithms.IndexOf(Algorithm) > -1 Then
		Algorithm = Algorithm.ToUpperCase
	Else
		Log("Algorithm not supported")
		Return
	End If
	If Base64Encode Then
		Private su As StringUtils
		Secret = su.EncodeBase64(Secret.GetBytes("UTF8"))
		'Secret = Utility.EncodeBase64(Secret.GetBytes("UTF8"))
		'Log ( Secret )
	End If
	Private AO As JavaObject
	AO.InitializeStatic("com.auth0.jwt.algorithms.Algorithm")
	ALG = AO.RunMethod(Algorithm, Array As String(Secret))
	
	JWT.InitializeStatic("com.auth0.jwt.JWT")
	builder = JWT.RunMethodJO("create", Null)
	verifier = JWT.RunMethodJO("require", Array(ALG)).RunMethodJO("build", Null)
	m_Initialized = True
End Sub

Public Sub IsInitialized As Boolean
	Return m_Initialized
End Sub

'Public Sub withIssuer (Issuer As String)
'	builder.RunMethodJO("withIssuer", Array(Issuer))
'End Sub
'
'Public Sub withClaim (Claim As Map)
'	For Each Key In Claim.Keys
'		builder.RunMethodJO("withClaim", Array(Key, Claim.Get(Key)))
'	Next
'End Sub
'
'Public Sub withExpiresAt (Date As Long)
'	Private jo As JavaObject
'	Private dt As Object = jo.InitializeNewInstance("java.util.Date", Array(Date))
'	builder.RunMethodJO("withExpiresAt", Array(dt))
'End Sub

Public Sub getIssuer As String
	Try
		Return Verify.RunMethod("getIssuer", Null)
	Catch
		Log(LastException)
	End Try
	Return Null
End Sub

Public Sub setIssuer (Issuer As String)
	builder.RunMethodJO("withIssuer", Array(Issuer))
End Sub

Public Sub getClaims As Map
	Try
		Return Verify.RunMethod("getClaims", Null)
	Catch
		Log(LastException)
	End Try
	Return Null
End Sub

Public Sub setClaims (Claims As Map)
	For Each Key In Claims.Keys
		builder.RunMethodJO("withClaim", Array(Key, Claims.Get(Key)))
	Next
End Sub

'iss	Issuer
'sub	Subject
'aud	Audience
'exp	Expiration
'nbf	Not Before
'iat	Issued At
'jti	JWT ID
Public Sub ReadClaim (Key As String) As Object
	Try
		'Return Verify.RunMethod("getClaims", Null).As(Map).Get(Key)
		Dim claims As Map = Verify.RunMethod("getClaims", Null)
		If claims.IsInitialized Then
			Return claims.Get(Key)
		Else
			Return Null
		End If
	Catch
		Log(LastException.Message)
	End Try
	Return Null
End Sub

'Public Sub setIssuedAt (IssueAt As Long)
'	Private jo As JavaObject
'	Private dt As Object = jo.InitializeNewInstance("java.util.Date", Array(IssueAt))
'	'Log(dt)
'	builder.RunMethodJO("withIssuedAt", Array(dt))
'	'm_IssuedAt = IssueAt
'End Sub
'
'Public Sub getIssuedAt As Long
'	Try
'		'Return ReadClaim("iat")
'		'Return Verify.RunMethod("getIssuedAt", Null)
'		Private dt As Object = Verify.RunMethod("getIssuedAt", Null)
'		Log(dt)
'		Return DateTime.DateParse(dt)
'	Catch
'		LogError(LastException)
'	End Try
'	Return 0
'	'Return m_IssuedAt
'End Sub

Public Sub getNotBefore As Object
	Try
		Return ReadClaim("nbf")
	Catch
		LogError(LastException)
	End Try
	Return Null
End Sub

Public Sub setExpiresAt (ExpiresAt As Object)
	Private jo As JavaObject
	Private dt As Object = jo.InitializeNewInstance("java.util.Date", Array(ExpiresAt))
	'Log(dt)
	builder.RunMethodJO("withExpiresAt", Array(dt))
End Sub

Public Sub getExpiresAt As Object
	Try
		'Private dt As Object = Verify.RunMethod("getExpiresAt", Null)
		'Log(dt)
		'Return DateTime.DateParse(dt)
		Return Verify.RunMethod("getExpiresAt", Null)
	Catch
		LogError(LastException)
	End Try
	Return Null
End Sub

Public Sub getToken As String
	Return m_Token
End Sub

Public Sub setToken (Token As String)
	m_Token = Token
End Sub

Public Sub getVerified As Boolean
	Return m_Verified
End Sub

'Public Sub getExpired As Boolean
'	Try
'		verifier.RunMethod("verify", Array(m_Token))
'		m_Expired = False
'	Catch
'		'Log(LastException)
'		If LastException.As(String).Contains("com.auth0.jwt.exceptions.TokenExpiredException") Then
'			m_Expired = True
'		End If
'	End Try
'	Return m_Expired
'End Sub

Public Sub getError As String
	Return m_Exception
End Sub

Public Sub Sign
	m_Token = builder.RunMethodJO("sign", Array(ALG))
End Sub

Public Sub Verify As JavaObject
	Try
		Private jo As JavaObject
		jo = verifier.RunMethod("verify", Array(m_Token))
		m_Verified = True
	Catch
		'Log(LastException)
		m_Exception = LastException.Message
		m_Verified = False
	End Try
	Return jo
End Sub

'Private Sub exp As Object
'	Try
'		Return Verify.RunMethod("getExpiresAt", Null)
'	Catch
'		Log(LastException)
'	End Try
'	Return Null
'End Sub

'Private Sub claims As Object
'	Try
'		Return Verify.RunMethod("getClaims", Null)
'	Catch
'		Log(LastException)
'	End Try
'	Return Null
'End Sub

'Public Sub getClaimByKey (Key As String) As Object
'	Try
'		Return claims.As(Map).Get(Key)
'	Catch
'		Log(LastException)
'	End Try
'	Return Null
'End Sub