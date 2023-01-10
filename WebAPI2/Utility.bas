B4J=true
Group=Modules
ModulesStructureVersion=1
Type=StaticCode
Version=8.1
@EndOfDesignText@
' Utility Code module
' Version 2.00
Sub Process_Globals
	Private const CONTENT_TYPE_JSON As String = "application/json"
	Private const CONTENT_TYPE_HTML As String = "text/html"
	Type HttpResponseMessage (ResponseCode As Int, ResponseString As String, ResponseData As List, ResponseMessage As String, ResponseError As Object, ResponseType As String, ContentType As String)
	Type HttpResponseContent (ResponseBody As String)
End Sub

Public Sub CheckMaxElements (Elements() As String, Max_Elements As Int) As Boolean
	If Elements.Length > Max_Elements Or Elements.Length = 0 Then
		Return False
	End If
	Return True
End Sub

Public Sub CheckAllowedVerb (SupportedMethods As List, Method As String) As Boolean
	'Methods: POST, GET, PUT, PATCH, DELETE
	If SupportedMethods.IndexOf(Method) = -1 Then
		Return False
	End If
	Return True
End Sub

Public Sub GetAPIPathElements (Path As String) As String()
	Dim part() As String = Regex.Split("\/", Path)
	Return part
End Sub

Public Sub BuildHtml (strHTML As String, Settings As Map) As String
	' Replace $KEY$ tag with new content from Map
 	strHTML = WebUtils.ReplaceMap(strHTML, Settings)
	Return strHTML
End Sub

Public Sub BuildView (strHTML As String, View As String) As String
	' Replace @VIEW@ tag with new content
	strHTML = strHTML.Replace("@VIEW@", View)
	Return strHTML
End Sub

Public Sub BuildTag (strHTML As String, Tag As String, Value As String) As String
	' Replace @TAG@ keyword with new content
	strHTML = strHTML.Replace("@" & Tag & "@", Value)
	Return strHTML
End Sub

Public Sub BuildDocView (strHTML As String, View As String) As String
	' Replace @DOCVIEW@ tag with new content
	strHTML = strHTML.Replace("@DOCVIEW@", View)
	Return strHTML
End Sub

'Public Sub BuildDocScript (strHTML As String, Script As String) As String
'	' Replace @DOCSCRIPT@ tag with new content
'	strHTML = strHTML.Replace("@DOCSCRIPT@", Script)
'	Return strHTML
'End Sub
'Public Sub BuildDocScript (strHTML As String, Script As String) As String
'	' Replace @DOCSCRIPT@ tag with new content
'	If Script.Length > 0 Then
'		Script = $"  <script>
'    $(document).ready(function() {
'    ${Script}
'    });
'  </script>"$
'		strHTML = strHTML.Replace("@DOCSCRIPT@", Script)
'	Else
'		strHTML = strHTML.Replace("@DOCSCRIPT@", "")
'	End If
'	Return strHTML
'End Sub
Public Sub BuildScript (strHTML As String, Script As String) As String
	' Replace @SCRIPT@ tag with new content
	strHTML = strHTML.Replace("@SCRIPT@", Script)
	Return strHTML
End Sub

' Insert inline JavaScript
Public Sub BuildScript2 (strHTML As String, Script As String, Settings As Map) As String
	' Replace @SCRIPT@ tag with new content
	Dim strScript As String = $"	<script type="text/javascript">
		${Script}
	</script>"$
	strScript = BuildHtml(strScript, Settings)
	strHTML = strHTML.Replace("@SCRIPT@", strScript)
	Return strHTML
End Sub

Public Sub ReadMapFile (FileDir As String, FileName As String) As Map
	Dim strPath As String = File.Combine(FileDir, FileName)
	Log($"Reading file (${strPath})..."$)
	Return File.ReadMap(FileDir, FileName)
End Sub

Public Sub ReadTextFile (FileName As String) As String
	Return File.ReadString(File.DirAssets, FileName)
End Sub

Public Sub WriteTextFile (FileName As String, Contents As String)
	File.WriteString(File.DirApp, FileName, Contents)
End Sub

Public Sub Map2Json (M As Map) As String
	Return M.As(JSON).ToString
End Sub

Public Sub List2Json (L As List) As String
	Return L.As(JSON).ToString
End Sub

Public Sub Object2Json (O As Object) As String
	Return O.As(JSON).ToString
End Sub

Public Sub RequestData (Request As ServletRequest) As Map
	Dim mdl As String = "RequestData"
	Try
		Dim data As Map
		Dim ins As InputStream = Request.InputStream
		If ins.BytesAvailable <= 0 Then
			Return data
		End If
		Dim tr As TextReader
		tr.Initialize(ins)
		Dim json As JSONParser
		json.Initialize(tr.ReadAll)
		data = json.NextObject
	Catch
		LogError($"${mdl} "$ & LastException)
	End Try
	Return data
End Sub

Public Sub RequestMultipartData (Request As ServletRequest) As Map
	Dim mdl As String = "RequestMultipartData"
	Try
		Dim data As Map
		'Dim ins As InputStream = Request.InputStream
		'Dim reqType As String = Request.GetParameter("type")
		
		'Dim conttype As String = Request.ContentType
		'Log ( "ct->" & conttype )
		
		'If reqType = "file" Then
		'Dim name As String = Request.GetParameter("name")
		'Dim name As String = data.Get("name")
		Dim fd As String =  File.DirApp & "\www\uploads" ' & Main.inspectFolder
		'File.MakeDir(File.DirApp , Main.inspectFolder)
		
'		If Request.ContentType="multipart/form-data" Then
'			' Upload
'			data = Request.GetMultipartData(fd, 100000000 * 1000) 'max 10000000000 bytes
'			If data.Size > 0 Then
'				For Each filename As String In  data.Keys
'					Log("Start uploading: " & filename)
'				Next
'			End If
'		End If
		
		data = Request.GetMultipartData(fd, 100000000 * 1000) 'max 10000000000 bytes
		For Each key As String In data.Keys
			Dim p As Part = data.Get(key)
			Dim d As Part = data.Get("datafile")
			Log ( "k->" &  key )
			Log ( "d->" &  d )
			Log ( "p->" & p )
			Dim name2 As String = File.GetName(p.TempFile)
			If key.StartsWith("post-") Then
				Dim name As String = p.SubmittedFilename 'data.Get("fn")
				If File.Exists(fd, name) Then File.Delete(fd, name)
				Dim out As OutputStream = File.OpenOutput( fd, name, False)
				Dim tmp As InputStream = File.OpenInput( fd, name2 )
				
				'File.Copy2(ins, out)
				File.Copy2(tmp, out)
				out.Close
				'Log("Postbyte Received : " & name & ", size=" & File.Size(fd, name))
				If File.Exists(fd, name) Then File.Delete(fd, name2)
				'resp.Write(" postbyte saved this file: "&name)
				'End If
			End If
			If key.StartsWith("json") Then
				'Log("key->" & key & ": " & p)
				'Log("p.SubmittedFilename->" & p.SubmittedFilename)
				'Log("p.TempFile->" & p.TempFile)
				'Log("p.IsFile->" & p.IsFile)
				'Log ( "value->" & p.GetValue(Request.CharacterEncoding) )
				
				tmp = File.OpenInput( fd, name2 )
				Dim tr As TextReader
				tr.Initialize(tmp)
		
				Dim json As JSONParser
				json.Initialize(tr.ReadAll)
				data = json.NextObject
				'Log ( data )
				
				If File.Exists(fd, name) Then File.Delete(fd, name2)
			End If
		Next
	Catch
		LogError($"${mdl} "$ & LastException)
	End Try
	Return data
End Sub

Public Sub RequestBasicAuth (req As ServletRequest) As Map
	Dim client As Map = CreateMap("CLIENT_ID": "", "CLIENT_SECRET": "")
	Dim auths As List = req.GetHeaders("Authorization")
	If auths.Size > 0 Then
		Dim auth As String = auths.Get(0)
		If auth.StartsWith("Basic") Then
			Dim b64 As String = auth.SubString("Basic ".Length)
			Dim su As StringUtils
			Dim b() As Byte = su.DecodeBase64(b64)
			Dim raw As String = BytesToString(b, 0, b.Length, "utf8")
			Dim UsernameAndPassword() As String = Regex.Split(":", raw)
			If UsernameAndPassword.Length = 2 Then
				client.Put("CLIENT_ID", UsernameAndPassword(0))
				client.Put("CLIENT_SECRET", UsernameAndPassword(1))
			End If
		End If
	End If
	Return client
End Sub

Public Sub RequestAccessToken (req As ServletRequest) As String
	Dim token As String
'	Dim jo As JavaObject = req
'	Dim collections As JavaObject
'	collections.InitializeStatic("java.util.Collections")
'	Dim headers As List = collections.RunMethod("list", Array(jo.RunMethodJO("getHeaderNames", Null)))
'	For Each h As String In headers
'		Log(h & ": " & req.GetHeader(h))
'	Next
	Dim auths As List = req.GetHeaders("Authorization")
	If auths.Size > 0 Then
		token = auths.Get(0)
	End If
	Return token
End Sub

Public Sub ReturnCookie (key As String, value As String, max_age As Int, http_only As Boolean, resp As ServletResponse)
	Dim session_cookie As Cookie
	session_cookie.Initialize(key, value)
	session_cookie.HttpOnly = http_only
	session_cookie.MaxAge = max_age
	resp.AddCookie(session_cookie)
End Sub

Public Sub ReturnConnect (resp As ServletResponse)
	Dim Result As List
	Result.Initialize
	Result.Add(CreateMap("connect": "true"))
	Dim Map1 As Map = CreateMap("s": "ok", "a": 200, "r": Result, "m": "Success", "e": Null)
	resp.Status = 200
	resp.ContentType = CONTENT_TYPE_JSON
	resp.Write(Map2Json(Map1))
End Sub

Public Sub ReturnError (Error As String, Code As Int, resp As ServletResponse)
	If Code = 0 Then Code = 400
	If Error = "" Then Error = "Bad Request"
	Dim Result As List
	Result.Initialize
	Dim Map1 As Map = CreateMap("s": "error", "a": Code, "r": Result, "m": Null, "e": Error)
	resp.Status = Code
	resp.ContentType = CONTENT_TYPE_JSON
	resp.Write(Map2Json(Map1))
End Sub

Public Sub ReturnSuccess (Data As Map, Code As Int, resp As ServletResponse)
	If Data.IsInitialized = False Then Data.Initialize
	If Code = 0 Then Code = 200
	Dim Result As List
	Result.Initialize
	Result.Add(Data)
	Dim Map1 As Map = CreateMap("s": "ok", "a": Code, "r": Result, "m": "Success", "e": Null)
	resp.Status = Code
	resp.ContentType = CONTENT_TYPE_JSON
	resp.Write(Map2Json(Map1))
End Sub

Public Sub ReturnSuccess2 (Data As List, Code As Int, resp As ServletResponse)
	If Data.IsInitialized = False Then Data.Initialize
	If Code = 0 Then Code = 200
	Dim Map1 As Map = CreateMap("s": "ok", "a": Code, "r": Data, "m": "Success", "e": Null)
	resp.Status = Code
	resp.ContentType = CONTENT_TYPE_JSON
	resp.Write(Map2Json(Map1))
End Sub

Public Sub ReturnBadRequest (resp As ServletResponse)
	ReturnError("Bad Request", 400, resp)
End Sub

Public Sub ReturnAuthorizationRequired (resp As ServletResponse)
	ReturnError("Authentication required", 401, resp)
End Sub

Public Sub ReturnMethodNotAllow (resp As ServletResponse)
	ReturnError("Method Not Allowed", 405, resp)
End Sub

Public Sub ReturnErrorInvalidInput (resp As ServletResponse)
	ReturnError("Error Invalid Input", 400, resp)
End Sub

Public Sub ReturnErrorCredentialNotProvided (resp As ServletResponse)
	ReturnError("Error Credential Not Provided", 400, resp)
End Sub

Public Sub ReturnErrorExecuteQuery (resp As ServletResponse)
	ReturnError("Error Execute Query", 422, resp)
End Sub

Public Sub ReturnSimpleConnect (Format As String, resp As ServletResponse)
	resp.Status = 200
	resp.ContentType = CONTENT_TYPE_JSON
	Select Format
		Case "Map"
			resp.Write(Map2Json(CreateMap("connect": "true")))
		Case Else ' "List"
			Dim Result As List
			Result.Initialize
			Result.Add(CreateMap("connect": "true"))
			resp.Write(List2Json(Result))
	End Select
End Sub

Public Sub ReturnSimpleSuccess (Data As Map, Code As Int, Format As String, resp As ServletResponse)
	If Code = 0 Then Code = 200
	resp.Status = Code
	resp.ContentType = CONTENT_TYPE_JSON
	If Data.IsInitialized = False Then Data.Initialize
	Select Format
		Case "Map"
			resp.Write(Map2Json(Data))
		Case Else ' "List"
			Dim Result As List
			Result.Initialize
			Result.Add(Data)
			resp.Write(List2Json(Result))
	End Select
End Sub

Public Sub ReturnSimpleError (Error As String, Code As Int, Format As String, resp As ServletResponse)
	If Code = 0 Then Code = 400
	If Error = "" Then Error = "Bad Request"
	resp.Status = Code
	resp.ContentType = CONTENT_TYPE_JSON
	Select Format
		Case "Map"
			resp.Write(Map2Json(CreateMap("error": Error)))
		Case Else ' "List"
			Dim Result As List
			Result.Initialize
			Result.Add(CreateMap("error": Error))
			resp.Write(List2Json(Result))
	End Select
End Sub

#Region Example
	' SimpleResponse = True
	' =================
	' Format: Map
	' {
	'     "connect": "true"
	' }
	'
	' Format: List
	' [
	'     {
	'         "connect": "true"
	'     }
	' ]
	'
	' SimpleResponse = False
	' ==================
	' {
	'     "m": "Success",
	'     "e": Null,
	'     "s": "ok",
	'     "r": [
	'         {
	'             "connect": "true"
	'         }
	'     ]
	'     "a": 200
	' }
#End Region
Public Sub ReturnSimpleHttpResponse (mess As HttpResponseMessage, SimpleResponseFormat As String, resp As ServletResponse)
	If mess.ResponseCode >= 200 And mess.ResponseCode < 300 Then ' SUCCESS
		If mess.ResponseString = "" Then mess.ResponseString = "ok"
		If mess.ResponseMessage = "" Then mess.ResponseMessage = "Success"
		mess.ResponseError = Null
	Else ' ERROR
		If mess.ResponseCode = 0 Then mess.ResponseCode = 400
		If mess.ResponseString = "" Then mess.ResponseString = "error"
		'If mess.ResponseMessage = "" Then mess.ResponseMessage = "Bad Request"
		If mess.ResponseCode = 405 Then mess.ResponseError = "Method Not Allowed"
		If mess.ResponseError = "" Then mess.ResponseError = "Bad Request"
		mess.ResponseMessage = Null
	End If
	If mess.ContentType = "" Then mess.ContentType = CONTENT_TYPE_JSON
	If mess.ResponseData.IsInitialized = False Then mess.ResponseData.Initialize
	' Override Status Code
	If mess.ResponseCode < 200 Or  mess.ResponseCode > 299 Then
		resp.Status = 200
	Else
		resp.Status = mess.ResponseCode
	End If
	resp.ContentType = mess.ContentType
	
'	Dim Map1 As Map
'	Map1.Initialize
'	'Map1.Put("m", mess.ResponseMessage)
'	'Map1.Put("e", mess.ResponseError)
'	'Map1.Put("s", mess.ResponseString)
'	Map1.Put("r", mess.ResponseData)
'	'Map1.Put("a", mess.ResponseCode)
'	Select Main.SimpleResponseFormat
'		Case "Map"
'			resp.Write(Map2Json(Map1))
'		Case Else ' "List"
'			Dim Result As List
'			Result.Initialize
'			Result.Add(Map1)
'			resp.Write(List2Json(Result))
'	End Select
	
	Select SimpleResponseFormat
		Case "Map"
			resp.Write(Map2Json(mess.ResponseData.Get(0)))
		Case Else ' "List"
			resp.Write(List2Json(mess.ResponseData))
	End Select
End Sub

Public Sub ReturnLocation (Location As String, resp As ServletResponse) ' Code = 302
	resp.SendRedirect(Location)
End Sub

Public Sub ReturnResponse (Message As HttpResponseMessage, SimpleResponse As Boolean, SimpleResponseFormat As String, resp As ServletResponse)
	If SimpleResponse Then
		ReturnSimpleHttpResponse(Message, SimpleResponseFormat, resp)
	Else
		ReturnHttpResponse(Message, resp)
	End If
End Sub

Public Sub ReturnHttpResponse (mess As HttpResponseMessage, resp As ServletResponse)
	If mess.ResponseCode >= 200 And mess.ResponseCode < 300 Then ' SUCCESS
		If mess.ResponseString = "" Then mess.ResponseString = "ok"
		If mess.ResponseMessage = "" Then mess.ResponseMessage = "Success"
		mess.ResponseError = Null
	Else ' ERROR
		If mess.ResponseCode = 0 Then mess.ResponseCode = 400
		If mess.ResponseString = "" Then mess.ResponseString = "error"
		'If mess.ResponseMessage = "" Then mess.ResponseMessage = "Bad Request"
		If mess.ResponseCode = 405 Then mess.ResponseError = "Method Not Allowed"
		If mess.ResponseError = "" Then mess.ResponseError = "Bad Request"
		mess.ResponseMessage = Null
	End If
	If mess.ContentType = "" Then mess.ContentType = CONTENT_TYPE_JSON
	If mess.ResponseData.IsInitialized = False Then mess.ResponseData.Initialize	
	' Override Status Code
	If mess.ResponseCode < 200 Or  mess.ResponseCode > 299 Then
		resp.Status = 200
	Else
		resp.Status = mess.ResponseCode
	End If
	resp.ContentType = mess.ContentType
	Dim Map1 As Map = CreateMap("s": mess.ResponseString, "a": mess.ResponseCode, "r": mess.ResponseData, "m": mess.ResponseMessage, "e": mess.ResponseError)
	
	' Send token to client as cookie
'	Dim munchies As Cookie
'	munchies.Initialize(Main.PREFIX & "token", mess.ResponseData.Get(0).As(Map).Get("token") )
'	munchies.HttpOnly = True
'	munchies.MaxAge = 15 * 60 ' seconds
'	resp.AddCookie(munchies)
	
	resp.Write(Map2Json(Map1))
End Sub

Public Sub ReturnHtml (str As String, resp As ServletResponse)
	resp.ContentType = CONTENT_TYPE_HTML
	resp.Write(str)
End Sub

Public Sub ReturnHtmlBody (cont As HttpResponseContent, resp As ServletResponse)
	resp.ContentType = CONTENT_TYPE_HTML
	resp.Write(cont.ResponseBody)
End Sub

'Public Sub ReturnHtmlBadRequest (resp As ServletResponse)
'	Dim str As String = $"<h1>Bad Request</h1>"$
'	ReturnHtml(str, resp)
'End Sub

Public Sub ReturnHtmlPageNotFound (resp As ServletResponse)
	Dim str As String = $"<h1>404 Page Not Found</h1>"$
	ReturnHtml(str, resp)
End Sub

Public Sub MD5 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "MD5")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub SHA1 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "SHA-1")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub SHA256 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "SHA-256")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub HMACSHA256 (str As String, key As String) As String
	Dim data() As Byte
	Dim MC As Mac
	Dim KG As KeyGenerator
	Dim BC As ByteConverter
	
	KG.Initialize("HMACSHA256")
	KG.KeyFromBytes(key.GetBytes("UTF8"))
	
	MC.Initialise("HMACSHA256", KG.Key)
	MC.Update(str.GetBytes("UTF8"))
	
	data = MC.Sign
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub GUID As String
	Dim sb As StringBuilder
	sb.Initialize
	For Each stp As Int In Array(8, 4, 4, 4, 12)
		If sb.Length > 0 Then sb.Append("-")
		For n = 1 To stp
			Dim c As Int = Rnd(0, 16)
			If c < 10 Then c = c + 48 Else c = c + 55
			sb.Append(Chr(c))
		Next
	Next
	Return sb.ToString
End Sub

Public Sub RandomString As String
	RndSeed(DateTime.Now)
	Dim gen As String = Rnd(1000, 9999)
	gen = gen & Rnd(10000, 99999)
	Return MD5( gen )
End Sub

Public Sub EncodeBase64 (data() As Byte) As String
	Dim su As StringUtils
	Return su.EncodeBase64(data)
End Sub

Public Sub DecodeBase64 (str As String) As Byte()
	Dim su As StringUtils
	Return su.DecodeBase64(str)
End Sub

Public Sub EncodeURL (str As String) As String
	Dim su As StringUtils
	Return su.EncodeUrl(str, "UTF8")
End Sub

Public Sub DecodeURL (str As String) As String
	Dim su As StringUtils
	Return su.DecodeUrl(str, "UTF8")
End Sub

'Public Sub ResizeImage
'	Private img As ImageScaler
'	img.Initialize
'	img.ResizeImage(File.DirApp, File.DirApp, "Sonic.jpg", 200, 200, "AUTOMATIC")
'	img.ResizeImage(File.DirApp, File.DirApp, "Puss.png", 300, 300, "FIT_TO_WIDTH")
'	img.ResizeImage(File.DirApp, File.DirApp, "Logo.bmp", 150, 150, "FIT_TO_HEIGHT")
'End Sub