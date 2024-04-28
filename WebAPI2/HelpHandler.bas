B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Help Handler class
' Version 2.07
Sub Class_Globals
	Private Request As ServletRequest 'ignore
	Private Response As ServletResponse
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	ShowHelpPage
End Sub

Private Sub ShowHelpPage
	Dim strMain As String = WebApiUtils.ReadTextFile("main.html")
	Dim strContents As String
	Dim strJSFile As String
	Dim strScripts As String
	
	#If RELEASE
	If File.Exists(File.DirApp, "help.html") Then
		strContents = File.ReadString(File.DirApp, "help.html")
	End If
	#Else
	' Generate API Documentation from Controller Classes
	strContents = ReadControllers(File.DirApp.Replace("\Objects", ""))
	If File.Exists(File.DirApp, "help.html") = False Then
		WebApiUtils.WriteTextFile("help.html", strContents)
	End If
	#End If
	
	strMain = WebApiUtils.BuildDocView(strMain, strContents)
	'' Requires EncryptionUtils
	'If Main.SESSIONS_ENABLED Then
	'	' Store csrf_token inside server session variables
	'	Dim HasherUtils As Hasher
	'	HasherUtils.Initialize
	'	Dim csrf_token As String =  HasherUtils.RandomHash2
	'	Request.GetSession.SetAttribute(Main.PREFIX & "csrf_token", csrf_token)
	'	' Append csrf_token into page header. Comment this line to check
	'	strMain = WebApiUtils.BuildCsrfToken(strMain, csrf_token)
	'End If
	strMain = WebApiUtils.BuildTag(strMain, "HELP", "") ' Hide API icon
	strMain = WebApiUtils.BuildHtml(strMain, Main.Config)
	If Main.SimpleResponse.Enable Then
		strJSFile = "webapi.help.verb.simple.js"
	Else
		strJSFile = "webapi.help.verb.js"
	End If
	strScripts = $"<script src="${Main.Config.Get("ROOT_URL")}/assets/js/${strJSFile}"></script>"$
	strMain = WebApiUtils.BuildScript(strMain, strScripts)
	WebApiUtils.ReturnHtml(strMain, Response)
End Sub

Public Sub ReadControllers (FileDir As String) As String
	Dim strHtml As String
	Log(" ")
	Log("Generating Help page ...")
	Log($"Reading controllers ..."$)
	
	Dim verbs(4) As String = Array As String("GET", "POST", "PUT", "DELETE")

	Dim DocumentedControllers As List
	DocumentedControllers.Initialize
	
	Dim Controllers As List = Main.Controllers
	For i = 0 To Controllers.Size - 1
		Dim TempController As String = Controllers.Get(i)
		' Avoid duplicate items
		If DocumentedControllers.IndexOf(TempController) = -1 Then ' bug 2022-08-29: Section(1) has double quotes
			DocumentedControllers.Add(TempController)
		End If
	Next
			
	For Each Controller As String In DocumentedControllers
		Dim Methods As List
		Methods.Initialize
				
		Dim SubStartsWithGet As List
		SubStartsWithGet.Initialize
	
		Dim SubStartsWithPost As List
		SubStartsWithPost.Initialize
	
		Dim SubStartsWithPut As List
		SubStartsWithPut.Initialize
	
		Dim SubStartsWithDelete As List
		SubStartsWithDelete.Initialize
	
		Dim VerbSubs As List
		VerbSubs.Initialize
		VerbSubs.Add(CreateMap(SubStartsWithGet: "SubStartsWithGet"))
		VerbSubs.Add(CreateMap(SubStartsWithPost: "SubStartsWithPost"))
		VerbSubs.Add(CreateMap(SubStartsWithPut: "SubStartsWithPut"))
		VerbSubs.Add(CreateMap(SubStartsWithDelete: "SubStartsWithDelete"))

		Dim ControllerName As String = Controller.Replace("Controller", "")
		strHtml = strHtml & GenerateHeaderByController(ControllerName)
		
		Dim List2 As List
		List2 = File.ReadList(FileDir, Controller & ".bas")

		For i = 0 To List2.Size - 1
			If List2.Get(i).As(String).StartsWith("'") Or List2.Get(i).As(String).StartsWith("#") Then
				' Ignore the line
			Else
				Dim index As Int = List2.Get(i).As(String).ToLowerCase.IndexOf("sub ") 'bug: desc may contain word like subject, so check "sub "
				If index > -1 Then
					Dim Line2 As String = List2.Get(i).As(String).SubString(index).Replace("Sub ", "").Trim
					For Each SubMap As Map In VerbSubs
						For Each val As String In SubMap.Values
							For Each verb In verbs
								If val.ToUpperCase.EndsWith(verb) And Line2.ToUpperCase.StartsWith(verb) Then
									For Each key As List In SubMap.Keys
										' Check commented code in between and ignore the rest of the code
										If Line2.IndexOf("'") > -1 Then
											Line2 = Line2.Replace(Line2.SubString(Line2.IndexOf("'")), "")
										End If
										If Line2.Contains("(") Then ' take 1st occurence
											Dim Arguments As String = Line2.SubString2(Line2.IndexOf("("), Line2.LastIndexOf(")")+1)
											Line2 = Line2.Replace(Arguments, "")
											Arguments = Arguments.Replace("(", "").Replace(")", "")
											Dim prm() As String
											prm = Regex.Split(",", Arguments)
											Dim plist As List
											plist.Initialize2(prm)
										Else
											Dim Arguments As String
											Dim plist As List
											plist.Initialize
										End If
										key.Add(Line2)

										Dim MethodProperties As Map = CreateMap("Verb": verb, "Method": Line2, "Args": Arguments, "Prm": plist, "Body": "&nbsp;", "File": False, "Plural": False, "Format": "")
										Methods.Add(MethodProperties)
									Next
								End If
							Next
						Next
					Next
				Else
					' =====================================================================
					' Detect commented hashtags inside Controller
					' =====================================================================
					' CAUTION: Do not use commented hashtag keyword inside non-verb subs!
					' =====================================================================
					' Supported hashtag keywords: (case-insensitive)
					' #name (formerly #plural)
					' #version
					' #desc
					' #body
					' #elements
					' #defaultformat
					' #upload
					'
					' Single keywords:					
					' #hide
					
					Dim Line3 As String = List2.Get(i).As(String)
					If Line3.IndexOf("'") > -1 Then
						' search for Version
						If Line3.ToLowerCase.IndexOf("#version") > -1 Then
							Dim ver() As String
							ver = Regex.Split("=", Line3)
							If ver.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Version", ver(1).Trim)
							End If
						End If
						
						' search for Desc
						If Line3.ToLowerCase.IndexOf("#desc") > -1 Then
							Dim desc() As String
							desc = Regex.Split("=", Line3)
							If desc.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Desc", desc(1).Trim)
							End If
						End If
						
						' search for Elements
						If Line3.ToLowerCase.IndexOf("#elements") > -1 Then
							Dim Elements() As String
							Elements = Regex.Split("=", Line3)
							If Elements.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Dim List3 As List = Elements(1).Trim.As(JSON).ToList
								Map3.Put("Elements", List3)
							End If
						End If
						
						' search for Body
						If Line3.ToLowerCase.IndexOf("#body") > -1 Then
							Dim body() As String
							body = Regex.Split("=", Line3)
							If body.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Body", body(1).Trim)
							End If
						End If

						' search for Name
						If Line3.ToLowerCase.IndexOf("#name") > -1 Then
							Dim name() As String
							name = Regex.Split("=", Line3)
							If name.Length = 2 Then
								' Override Controller with name
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Controller", name(1).Trim)
							End If
						End If

						' search for Hide
						If Line3.ToLowerCase.IndexOf("#hide") > -1 Then
							Dim Map3 As Map = Methods.Get(Methods.Size-1)
							Map3.Put("Hide", True)
						End If
						
						' search for Upload
						If Line3.ToLowerCase.IndexOf("#upload") > -1 Then
							Dim upd() As String
							upd = Regex.Split("=", Line3)
							If upd.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Upload", upd(1).Trim)
							End If
						End If
						
						' search for DefaultFormat
						If Line3.ToLowerCase.IndexOf("#defaultformat") > -1 Then
							Dim fmt() As String
							fmt = Regex.Split("=", Line3)
							If fmt.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								If fmt(1).Trim = "raw" Then
									Map3.Put("Format", "raw")
								End If
							End If
						End If
					End If
				End If
			End If
		Next
				
		For Each m As Map In Methods
			Dim MM(2) As String
			MM = Regex.Split(" As ", m.Get("Method")) ' Ignore return type
			Dim MethodName As String = MM(0).Trim
			If m.ContainsKey("Hide") Then Continue ' Skip Hidden sub
			' Default controller for singular
			If m.ContainsKey("Controller") = False Then m.Put("Controller", ControllerName)
			strHtml = strHtml & GenerateDocItem(m.Get("Version"), m.Get("Controller"), m.Get("Elements"), m.Get("Verb"), MethodName, m.Get("Prm"), m.Get("Body"), m.Get("Upload"), m.Get("Format"), m.Get("Desc"))
		Next

		' Retain this part for debugging purpose
		'#If debug
		'For Each m As Map In Methods
		'	Log(" ")
		'	Log("[" & m.Get("Verb") & "]")
		'	Log(m.Get("Method"))
		'	Dim MM(2) As String
		'	MM = Regex.Split(" As ", m.Get("Method")) ' Ignore return type
		'	Log("Sub Name: " & MM(0).Trim)
		'	Dim Lst As List
		'	Lst.Initialize
		'	Lst = m.Get("Prm")
		'	For i = 0 To Lst.Size - 1
		'		Dim pm() As String
		'		pm = Regex.Split(" as ", Lst.Get(i).As(String).ToLowerCase)
		'		Log(pm(0).Trim & " [" & pm(1).Trim & "]")
		'	Next
		'	Log("Hide: " & m.Get("Hide"))
		'	Log("Plural: " & m.Get("Plural"))
		'	Log("Elements: " & m.Get("Elements"))
		'	Log("Version: " & m.Get("Version"))
		'	Log("Format: " & m.Get("Format"))
		'	Log("Desc: " & m.Get("Desc"))
		'Next
		'#End If
	Next

	Log($"Help page has been generated."$)
	Return strHtml
End Sub

Private Sub GenerateLink (ApiVersion As String, Controller As String, Elements As List) As String
	If ApiVersion.EqualsIgnoreCase("null") Then
		Dim Link As String = Main.Config.Get("ROOT_PATH")
		If Link.EndsWith("/") = False Then Link = Link & "/"
	Else
		Dim Link As String = Main.Config.Get("ROOT_PATH") & Main.Config.Get("API_NAME")
		If Link.EndsWith("/") = False Then Link = Link & "/"
		If Main.Element.Api.Versioning Then Link = Link & ApiVersion
		If Link.EndsWith("/") = False Then Link = Link & "/"
	End If

	Link = Link & Controller.ToLowerCase

	For i = 0 To Elements.Size - 1
		Link = Link & "/" & Elements.Get(i)
	Next

	Return Link
End Sub

Public Sub GenerateVerbSection (Verb As String, strColor As String, strButtonID As String, strLink As String, blnRaw As Boolean, strFileUpload As String, strDesc As String, strParams As String, strBody As String, strExpected As String, strInputDisabled As String, strDisabledBackground As String) As String
	Dim strBgColor As String
	Select strColor.ToLowerCase
		Case "success"
			strBgColor = "#d4edda"
		Case "warning"
			strBgColor = "#fff3cd"
		Case "primary"
			strBgColor = "#cce5ff"
		Case "danger"
			strBgColor = "#f8d7da"
	End Select
	Dim strFormat As String
	If blnRaw Then strFormat = "?format=json"
	Dim strBodySample As String
	Dim strBodyInput As String
	Select strFileUpload
		Case "Image"
			strBodySample = ""
			strBodyInput = $"File: <label for="file1${strButtonID}">Choose an image file:</label><input type="file" id="file1${strButtonID}" class="pb-3" name="file1" accept="image/png, image/jpeg, application/pdf">"$
			'strFileUpload = ""
		Case "PDF"
			strBodySample = ""
			strBodyInput = $"File: <label for="file1${strButtonID}">Choose a PDF file:</label><input type="file" id="file1${strButtonID}" class="pb-3" name="file1" accept="application/pdf">"$
			'strFileUpload = ""
		Case Else
			strBodySample = $"Format: <p class="form-control" style="height: fit-content; background-color: #F0F9FF; font-size: small">${strBody}</p>"$
			strBodyInput = $"Body: <textarea id="body${strButtonID}" rows="6" class="form-control data-body" style="background-color: #FFFFFF; font-size: small"></textarea></p>"$
			'strFileUpload = ""
	End Select
	Dim strHtml As String = $"
		<button class="collapsible" style="background-color: ${strBgColor}"><span class="badge badge-${strColor} p-1">${Verb}</span> ${strLink}</button>
        <div class="details">
			<div class="row">
				<div class="col-md-6 pt-3">
					${strDesc}
				</div>
			</div>
			<div class="row">
	            <div class="col-md-3 p-3">
					<p><strong>Parameters</strong><br/>
	                <label class="col control-label border rounded" style="padding-top: 5px; padding-bottom: 5px; background-color: #F0F9FF; font-size: small; white-space: pre-wrap;">${strParams}</label></p>					
	                ${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), strBodySample, "")}
	            	<p><strong>Status Code</strong><br/>
					${strExpected}</p>
				</div>
	            <div class="col-md-3 p-3">
					<form id="form1" method="${Verb}">
					<p><strong>Path</strong><br/>
	                <input${IIf(strInputDisabled.Length > 0, " " & strInputDisabled, "")} id="path${strButtonID}" class="form-control data-path" style="background-color: ${IIf(strInputDisabled.EqualsIgnoreCase("disabled"), strDisabledBackground, "#FFFFFF")}; font-size: small" value="${strLink & strFormat}"></p>
					${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), strBodyInput, $""$)}
	                <button id="${strButtonID}" class="${IIf(strFileUpload.EqualsIgnoreCase("Image") Or strFileUpload.EqualsIgnoreCase("PDF"), $"file"$, $"${Verb.ToLowerCase}"$)} button btn-${strColor} col-md-6 col-lg-4 p-2 float-right" style="cursor: pointer; padding-bottom: 60px"><strong>Submit</strong></button>
	            	</form>								
				</div>
				<div class="col-md-6 p-3">
					<p><strong>Response</strong><br/>
					<textarea rows="10" id="response${strButtonID}" class="form-control" style="background-color: #696969; color: white; font-size: small"></textarea></p>
					<div id="alert${strButtonID}" class="alert alert-default" role="alert" style="display: block"></div>
				</div>
			</div>
        </div>"$
	Return strHtml
End Sub

Public Sub GenerateHeaderByController (Header As String) As String
	Dim strHtml As String = $"
		<div class="row mt-3">
            <div class="col-md-12">
                <h6 class="text-uppercase text-primary"><strong>${Header}</strong></h6>
            </div>
		</div>"$
	Return strHtml
End Sub

Public Sub GenerateDocItem (ApiVersion As String, Controller As String, Elements As List, Verb As String, MethodName As String, Params As List, Body As String, FileUpload As String, DefaultFormat As String, Desc As String) As String
	Dim strHTML As String
	Dim strParams As String
	Dim strColor As String
	Dim strLink As String
	Dim blnRaw As Boolean
	Dim strExpected As String = "200 Success"
	Dim strInputDisabled As String
	Dim strDisabledBackground As String = "#FFFFFF"
	Select Verb
		Case "GET"
			strColor = "success"
		Case "POST"
			strColor = "warning"
			strExpected = "201 Created"
		Case "PUT"
			strColor = "primary"
		Case "DELETE"
			strColor = "danger"
	End Select
	' Add other expected response
	strExpected = strExpected & "<br/>400 Bad request"
	strExpected = strExpected & "<br/>404 Not found"
	strExpected = strExpected & "<br/>422 Error execute query"

	If Params.Size > 0 Then
		For i = 0 To Params.Size - 1
			If i > 0 Then strParams = strParams & CRLF
			Dim pm() As String
			pm = Regex.Split(" As ", Params.Get(i))
			strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]"
		Next
	Else
		strParams = "Not required"
		strInputDisabled = "disabled"
		strDisabledBackground = "#F0F9FF"
	End If
	If Not(Elements.IsInitialized) Then Elements.Initialize
	strLink = GenerateLink(ApiVersion, Controller, Elements)
	If DefaultFormat.EqualsIgnoreCase("raw") And Verb = "GET" Then blnRaw = True
	strHTML = strHTML & GenerateVerbSection(Verb, strColor, "btn" & MethodName & Controller, strLink, blnRaw, FileUpload, Desc, strParams, Body, strExpected, strInputDisabled, strDisabledBackground)
	Return strHTML
End Sub