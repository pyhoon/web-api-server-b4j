B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' JSON Web Token class
' Version 2.00
' Additional Libraries: jStringUtils, JavaObject
' Stop using JWTs! https://gist.github.com/samsch/0d1f3d3b4745d778f78b230cf6061452
' YouTube https://www.youtube.com/watch?v=pYeekwv3vC4
Sub Class_Globals
	Private JWT As JavaObject
	Private ALG As JavaObject
	Private builder As JavaObject
	Private verifier As JavaObject
	Private decoded As JavaObject
	'Private m_IssuedAt As String
	Private m_Issuer As String
	Private m_Claims As Map
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

Public Sub getIssuer As String
	Dim iss As String
	Try
		If m_Verified Then
			iss = decoded.RunMethod("getIssuer", Null)			
		End If
		m_Issuer = iss
	Catch
		m_Exception = LastException.Message
		Log(m_Exception)
	End Try
	Return m_Issuer
End Sub

Public Sub setIssuer (Issuer As String)
	Try
		builder.RunMethodJO("withIssuer", Array(Issuer))
	Catch
		m_Exception = LastException.Message
		Log(m_Exception)
	End Try
	m_Issuer = Issuer
End Sub

Public Sub getClaims As Map
	Dim clm As Map
	Try
		If m_Verified Then
			clm = decoded.RunMethod("getClaims", Null)
		End If
		m_Claims = clm
	Catch
		m_Exception = LastException.Message
		Log(m_Exception)
	End Try
	Return m_Claims
End Sub

Public Sub setClaims (Claims As Map)
	For Each Key In Claims.Keys
		builder.RunMethodJO("withClaim", Array(Key, Claims.Get(Key)))
	Next
	m_Claims = Claims
End Sub

'iss	Issuer
'sub	Subject
'aud	Audience
'exp	Expiration
'nbf	Not Before
'iat	Issued At
'jti	JWT ID
Public Sub ReadClaim (Key As String) As Object
	Return getClaims.Get(Key)
End Sub

Public Sub getNotBefore As Object
	Return ReadClaim("nbf")
End Sub

Public Sub getExpiresAt As Object
	Private exp As Object
	Try
		If m_Verified Then
			'exp = decoded.RunMethod("getExpiration", Null)
			exp = decoded.RunMethod("getExpiresAt", Null)
		End If
	Catch
		m_Exception = LastException.Message
		Log(m_Exception)
	End Try
	Return exp
End Sub

Public Sub setIssuedAt (IssuedAt As Object)
	Private jo As JavaObject = Me
	'Log( "IssuedAt=" & IssuedAt )
	Private dt As Object = jo.InitializeNewInstance("java.util.Date", Array(IssuedAt))
	'Log( "dt=" & dt )
	builder.RunMethodJO("withIssuedAt", Array(dt))
End Sub

Public Sub setExpiresAt (ExpiresAt As Object)
	Private jo As JavaObject = Me
	'Log( "ExpiresAt=" & ExpiresAt )
	Private dt As Object = jo.InitializeNewInstance("java.util.Date", Array(ExpiresAt))
	'Log( "dt=" & dt )
	builder.RunMethodJO("withExpiresAt", Array(dt))
End Sub

Public Sub getToken As String
	Return m_Token
End Sub

Public Sub setToken (Token As String)
	m_Token = Token
End Sub

Public Sub Verify As JavaObject
	Try
		decoded = verifier.RunMethod("verify", Array(m_Token))		
		m_Verified = True		
	Catch
		m_Exception = LastException.Message
		'Log(m_Exception)
		m_Verified = False
	End Try
	Return decoded
End Sub

Public Sub getVerified As Boolean
	Return m_Verified
End Sub

Public Sub getError As String
	Return m_Exception
End Sub

Public Sub Sign
	m_Token = builder.RunMethodJO("sign", Array(ALG))
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