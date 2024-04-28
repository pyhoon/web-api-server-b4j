B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Server Configuration class
' Version 2.07
Sub Class_Globals
	Private SERVER_PORT As Int
	Private SSL_PORT As Int
	Private ROOT_URL As String
	Private ROOT_PATH As String
	Private API_PATH As String
	Private API_NAME As String
	Private API_VERSIONING As String
	Private SSL_KEYSTORE_DIR As String
	Private SSL_KEYSTORE_FILE As String
	Private SSL_KEYSTORE_PASSWORD As String
	Private ENABLE_SSL As Boolean
	Private ENABLE_CORS As Boolean
	Private ENABLE_HELP As Boolean
	Private ENABLE_BASIC_AUTH As Boolean
	Private ENABLE_JWT_AUTH As Boolean
	Private SESSIONS_ENABLED As Boolean
	Private COOKIES_ENABLED As Boolean
	Private COOKIES_EXPIRATION As Long
	Private STATIC_FILES_BROWSING As Boolean
	Private STATIC_FILES_FOLDER As String
	Private SIMPLE_RESPONSE As SimpleResponse
End Sub

Public Sub Initialize
	' Read environment settings
	If Not(File.Exists(File.DirApp, "config.ini")) Then
		File.Copy(File.DirAssets, "config.example", File.DirApp, "config.ini")
	End If
	Main.Config = WebApiUtils.ReadMapFile(File.DirApp, "config.ini")
	Main.Config.Put("VERSION", Main.VERSION)
	'Main.Config.Put("PREFIX", Main.PREFIX)
	
	' Initialize Simple Response
	SIMPLE_RESPONSE.Initialize
	
	' Setting default static files folder
	STATIC_FILES_FOLDER = File.Combine(File.DirApp, "www")
	
	' Load configuration to variables
	SERVER_PORT = Main.Config.GetDefault("ServerPort", 0)
	SSL_PORT = Main.Config.GetDefault("SSLPort", 0)
	ROOT_URL = Main.Config.GetDefault("ROOT_URL", "http://localhost")
	ROOT_PATH = Main.Config.GetDefault("ROOT_PATH", "/web/")
	API_NAME = Main.Config.GetDefault("API_NAME", "api")
	API_VERSIONING = Main.Config.GetDefault("API_VERSIONING", "True")
	
	' Set KeyStore file
	SSL_KEYSTORE_DIR = Main.Config.GetDefault("SSL_KEYSTORE_DIR", "")
	SSL_KEYSTORE_FILE = Main.Config.GetDefault("SSL_KEYSTORE_FILE", "")
	SSL_KEYSTORE_PASSWORD = Main.Config.GetDefault("SSL_KEYSTORE_PASSWORD", "")
End Sub

' Apply Server Configurations
Public Sub Finalize
	ConfigurePort
	ConfigurePaths
	ConfigureElements
	ConfigureHandlers
	ConfigureCORS
	ConfigureSSL
	ConfigureBasicAuth
	ConfigureJWTAuth
	ConfigureSessions
	ConfigureCookies
	ConfigureStaticFiles
	ConfigureSimpleResponse
End Sub

' Display some information in Logs (debug) or terminal (release)
Public Sub ShowWelcomeText
	Log($"Web API Server (version = ${Main.VERSION}) is running on port ${Main.Server.Port}${IIf(Main.Server.SslPort > 0, $" (redirected to port ${Main.Server.SslPort})"$, "")}"$)
	Log($"Open the following URL from your web browser"$)
	Log(ROOT_URL & ROOT_PATH)
End Sub

Public Sub getServerPort As Int
	Return SERVER_PORT
End Sub

Public Sub getSSLPort As Int
	Return SSL_PORT
End Sub

Public Sub getEnableSSL As Boolean
	Return ENABLE_SSL
End Sub

Public Sub getEnableCORS As Boolean
	Return ENABLE_CORS
End Sub

Public Sub getEnableHelp As Boolean
	Return ENABLE_HELP
End Sub

Public Sub getBasicAuthentication As Boolean
	Return ENABLE_BASIC_AUTH
End Sub

Public Sub getJsonWebToken As Boolean
	Return ENABLE_JWT_AUTH
End Sub

Public Sub getEnableSessions As Boolean
	Return SESSIONS_ENABLED
End Sub

Public Sub getEnableCookies As Boolean
	Return COOKIES_ENABLED
End Sub

Public Sub getCookiesExpiration As Long
	Return COOKIES_EXPIRATION
End Sub

Public Sub getRootUrl As String
	Return ROOT_URL
End Sub

Public Sub getRootPath As String
	Return ROOT_PATH
End Sub

Public Sub getStaticFilesBrowsable As Boolean
	Return STATIC_FILES_BROWSING
End Sub

Public Sub getStaticFilesFolder As String
	Return STATIC_FILES_FOLDER
End Sub

Public Sub getSimpleResponse As SimpleResponse
	Return SIMPLE_RESPONSE
End Sub

' Set Server Port
Public Sub setServerPort (Value As Int)
	SERVER_PORT = Value
End Sub

' Set SSL Port
Public Sub setSSLPort (Value As Int)
	SSL_PORT = Value
End Sub

' Enable HTTPS
Public Sub setEnableSSL (Value As Boolean)
	ENABLE_SSL = Value
End Sub

' Enable Cross Origin filter
Public Sub setEnableCORS (Value As Boolean)
	ENABLE_CORS = Value
End Sub

' Enable Documentation
Public Sub setEnableHelp (Value As Boolean)
	ENABLE_HELP = Value
End Sub

' Enable Basic Authentication
Public Sub setBasicAuthentication (Value As Boolean)
	ENABLE_BASIC_AUTH = Value
End Sub

' Enable JSON Web Token Authentication
Public Sub setJsonWebToken (Value As Boolean)
	ENABLE_JWT_AUTH = Value
End Sub

' Enable Sessions
Public Sub setEnableSessions (Value As Boolean)
	SESSIONS_ENABLED = Value
End Sub

' Enable Cookies
Public Sub setEnableCookies (Value As Boolean)
	COOKIES_ENABLED = Value
End Sub

' Set Cookies Expiration (in seconds)
Public Sub setCookiesExpiration (Value As Long)
	COOKIES_EXPIRATION = Value
End Sub

' Set Root URL
Public Sub setRootUrl (Value As String)
	ROOT_URL = Value
End Sub

' Set Root Path
Public Sub setRootPath (Value As String)
	ROOT_PATH = Value
End Sub

' Allow Browsing Static Files Directory
Public Sub setStaticFilesBrowsable (Value As Boolean)
	STATIC_FILES_BROWSING = Value
End Sub

' Set Static Files Folder
Public Sub setStaticFilesFolder (Value As String)
	STATIC_FILES_FOLDER = Value
End Sub

' Set Simple JSON Response (disabled by default)
' =======================================================================================
' By default, standard JSON format will be returned
' It is a map with keys 'm', 'e', 's', 'r', 'a' where the response (r) is always a list
' When enabled, JSON format can be set to 'Auto', 'List' or 'Map'
' SimpleResponse.Format = "Auto"	' no conversion
' SimpleResponse.Format = "List"	' always convert to a list
' SimpleResponse.Format = "Map"	' always convert to a map with "data" as the default key
' SimpleResponse.DataKey = "data"	' overwrite with different key
' =======================================================================================
Public Sub setSimpleResponse (Value As SimpleResponse)
	SIMPLE_RESPONSE = Value
End Sub

' Set Server Port
Private Sub ConfigurePort
	If IsNumber(SSL_PORT) = False Then SSL_PORT = 0
	If SERVER_PORT = 0 Then
		SERVER_PORT = 8080
		Log($"Server Port is set to 8080"$)
	Else
		Main.Server.Port = SERVER_PORT
	End If
End Sub

' Set Paths
Private Sub ConfigurePaths
	If SSL_PORT <> 0 Then
		If SSL_PORT <> 443 Then
			ROOT_URL = ROOT_URL & ":" & SSL_PORT
		End If
		ROOT_URL = ROOT_URL.Replace("http:", "https:")
	Else
		If SERVER_PORT <> 80 Then
			ROOT_URL = ROOT_URL & ":" & SERVER_PORT
		End If
	End If
	Main.Config.Put("ROOT_URL", ROOT_URL)
	
	' Root Path
	If ROOT_PATH = "" Then ROOT_PATH = "/"
	If ROOT_PATH <> "/" Then
		If ROOT_PATH.StartsWith("/") = False Then ROOT_PATH = "/" & ROOT_PATH
		If ROOT_PATH.EndsWith("/") = False Then ROOT_PATH = ROOT_PATH & "/"
	End If
	Main.Config.Put("ROOT_PATH", ROOT_PATH)
	
	' API Name
	API_NAME = API_NAME.Replace("/", "")
	Main.Config.Put("API_NAME", API_NAME)
	
	' API Path
	API_PATH = IIf(API_NAME.Length > 0, API_NAME & "/", "")
	Main.Config.Put("API_PATH", API_PATH)
End Sub

' Set Elements
Private Sub ConfigureElements
	Main.Element.Initialize
	Main.Element.Elements.Initialize
	
	Main.Element.Web.Root = "/" ' just a placeholder
	Main.Element.Elements.Add(Main.Element.Web.Root)
	
	Main.Element.Web.Path = ROOT_PATH
	If Main.Element.Web.Path.EqualsIgnoreCase("/") = False Then
		Main.Element.Elements.Add(Main.Element.Web.Path)
		Main.Element.PathIndex = 1
	End If
	
	Main.Element.Api.Name = API_NAME
	If Main.Element.Api.Name.Trim.Length > 0 Then
		Main.Element.Elements.Add(Main.Element.Api.Name)
	End If
	
	' API Versioning
	If API_VERSIONING.EqualsIgnoreCase("True") Then
		Main.Element.Api.Versioning = True
		Main.Element.Elements.Add("version") ' just a placeholder
	Else
		Main.Element.Api.Versioning = False
		Main.Config.Put("API_VERSIONING", False)
	End If
	
	Main.Element.ApiVersionIndex = Main.Element.Elements.Size - 1
	Main.Element.ApiControllerIndex = Main.Element.Elements.Size
	Main.Element.WebControllerIndex = Main.Element.Elements.Size - IIf(Main.Element.Api.Name.Length = 0, 0, 1) - IIf(Main.Element.Api.Versioning, 1, 0) ' or just Element.PathIndex + 1
	'#If DEBUG
	'Dim i As Int
	'For Each item In Element.Elements
	'	LogDebug($"${i} - ${item}"$)
	'	i = i + 1
	'Next
	'LogDebug($"PathIndex=${Element.PathIndex}"$)
	'LogDebug($"WebControllerIndex=${Element.WebControllerIndex}"$)
	'LogDebug($"ApiControllerIndex=${Element.ApiControllerIndex}"$)
	'LogDebug($"ApiVersionIndex=${Element.ApiVersionIndex}"$)
	'#End If
End Sub

' Set Handlers
Private Sub ConfigureHandlers
	If API_NAME.Length = 0 Then
		' ===================================================================
		' Note: You can either enable ApiHandler or WebHandler, not both
		' ===================================================================
		' API route - /web/ (root path is used for single API handler)
		' ===================================================================
		Main.Server.AddHandler(ROOT_PATH & "*", "ApiHandler", False)			' Add API handler (WebHandler disabled)
		' ===================================================================
		' OR
		' ===================================================================
		' Web route - /web/ (root path is used for single web handler)
		' ===================================================================
		'Server.AddHandler(ROOT_PATH & "*", "WebHandler", False)				' Add Web handler (ApiHandler disabled)
	Else
		' ===================================================================
		' Note: You can enable both ApiHandler and WebHandler
		' ===================================================================
		' API route - /web/api/ (recommended)
		' ===================================================================
		Main.Server.AddHandler(ROOT_PATH & API_PATH & "*", "ApiHandler", False) ' Add API handler
		' AND
		' ===================================================================
		' Web route - /web/ (optional)
		' ===================================================================
		Main.Server.AddHandler(ROOT_PATH & "*", "WebHandler", False) 			' Add Web handler
	End If
	' =======================================================================
	' Note: Documentation for debugging APIs without client app or Postman
	' =======================================================================
	' Help route - /web/help (optional)
	' =======================================================================
	If ENABLE_HELP Then
		Main.Server.AddHandler(ROOT_PATH & "help", "HelpHandler", False) 		' Add Help handler
		Main.SHOW_API_ICON = True
	End If
	' =======================================================================
	' Web Sockets route (optional)
	' =======================================================================
	'Server.AddWebSocket("/time", "WSTime")										' Add Web socket
End Sub

' Configure SSL and Keystore
Private Sub ConfigureSSL
	If Not(ENABLE_SSL) Then Return
	If SSL_PORT = 0 Then Return
	
	Dim ssl As SslConfiguration
	ssl.Initialize
	ssl.SetKeyStorePath(SSL_KEYSTORE_DIR, SSL_KEYSTORE_FILE)
	ssl.KeyStorePassword = SSL_KEYSTORE_PASSWORD
	'ssl.KeyManagerPassword = ""
	Main.Server.SetSslConfiguration(ssl, SSL_PORT)
	
	'add filter to redirect all traffic from http to https (optional)
	Main.Server.AddFilter("/*", "HttpsFilter", False)
End Sub

' Configure Cross Origin in JavaScript call
Private Sub ConfigureCORS
	' =========================================================
	' Note: If you have enabled JWT then you may not need this
	' =========================================================
	' allowedOrigins = "*" or "http://google.com"
	' allowedMethods = "*" or "GET,POST,HEAD"
	' allowedHeaders = "*" or "X-Requested-With,Content-Type,Accept,Origin"
	' Eg. ConfigureCORS(ROOT_PATH & "account/*", "*", "", "")
	' Reference: https://www.b4x.com/android/forum/threads/jetty-cross-origin-filter-to-be-added-to-jserver-library.85641/
	' =========================================================
	If Not(ENABLE_CORS) Then Return
	Dim Paths As List
	Paths.Initialize
	
	'Paths.Add(CreateMap("path": "*", "origins": "*", "methods": "POST,PUT,DELETE", "headers": "*")) 		' All origins access (* methods not working)
	Paths.Add(CreateMap("path": ROOT_PATH & API_PATH & "v2/data/*", "origins": "http://localhost, http://127.0.0.1:3000", "methods": "POST,PUT,DELETE", "headers": "*")) ' vue.js prod/dev app
	
	For Each Item As Map In Paths
		Dim cors As CorsFilter
		cors.Initialize(Item.Get("path"), _
		CreateMap( _
		"allowedOrigins": Item.Get("origins"), _
		"allowedMethods": Item.Get("methods"), _
		"allowedHeaders": Item.Get("headers"), _
		"allowCredentials": "true", _
		"preflightMaxAge": 1800, _
		"chainPreflight": "false"))
		cors.AddToServer(Main.Server)
	Next
End Sub

' Add <link>BasicAuthFilter|https://www.b4x.com/android/forum/threads/web-api-template-2.143310/#post-908109</link> class to the Modules tab
' Add the following lines to Process_Globals <code>
' Public AUTHENTICATION_TYPE As String
' Public AUTH As AUTH</code>
Private Sub ConfigureBasicAuth
	' =============================================
	' Not recommended for Web Based Authentication
	' =============================================
	If Not(ENABLE_BASIC_AUTH) Then Return
	'AUTHENTICATION_TYPE = "BASIC AUTHENTICATION"
	
	Dim Paths As List
	Paths.Initialize
	Paths.Add(ROOT_PATH & "dashboard")
	
	For Each path In Paths
		'Log(path)
		Main.Server.AddFilter(path, "BasicAuthFilter", False)
	Next
End Sub

' Add <link>JSONWebToken|https://www.b4x.com/android/forum/threads/web-api-template-2.143310/#post-908109</link> and <link>JWTAuthFilter|https://www.b4x.com/android/forum/threads/web-api-template-2.143310/#post-908109</link> classes to the Modules tab
' Add the following line to Process_Globals <code>
' Public AUTHENTICATION_TYPE As String
' Public JAT As JSONWebToken
' Public JRT As JSONWebToken
' Public Secret As Secret
' Type Secret (Access_Token As String, Refresh_Token As String)</code>
Private Sub ConfigureJWTAuth
	' =================================================================
	' Why don't use JWTs?
	' https://gist.github.com/samsch/0d1f3d3b4745d778f78b230cf6061452
	' =================================================================
	If Not(ENABLE_JWT_AUTH) Then Return
	'AUTHENTICATION_TYPE = "JSON WEB TOKEN AUTHENTICATION"
	'LogColor($"Authentication: ${AUTHENTICATION_TYPE}"$, -65536)
	
	'JAT.Initialize("HMAC256", Secret.Access_Token, False)
	'JAT.Issuer = ROOT_URL
	
	'JRT.Initialize("HMAC256", Secret.Refresh_Token, False)
	'JRT.Issuer = ROOT_URL
	
	Dim Paths As List
	Paths.Initialize
	Paths.Add(ROOT_PATH & "help")
	
	For Each path In Paths
		'Log(path)
		Main.Server.AddFilter(path, "JWTAuthFilter", False)
	Next
End Sub

' Configure Sessions
Private Sub ConfigureSessions
	Main.SESSIONS_ENABLED = SESSIONS_ENABLED
End Sub

' Configure Cookies
Private Sub ConfigureCookies
	Main.COOKIES_ENABLED = COOKIES_ENABLED
	Main.COOKIES_EXPIRATION = COOKIES_EXPIRATION
End Sub

' Configure permission for browsing static files folder
Private Sub ConfigureStaticFiles
	Main.Server.StaticFilesFolder = STATIC_FILES_FOLDER
	Main.Server.SetStaticFilesOptions(CreateMap("dirAllowed": STATIC_FILES_BROWSING))
End Sub

' Configure Simple JSON Response
Private Sub ConfigureSimpleResponse
	Main.SimpleResponse = SIMPLE_RESPONSE
End Sub