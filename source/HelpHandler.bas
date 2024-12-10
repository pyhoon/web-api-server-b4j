B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
'Help Handler class
'Version 3.10
Sub Class_Globals
	Private Request As ServletRequest 'ignore
	Private Response As ServletResponse
	Type VerbSection (Verb As String, Color As String, ElementId As String, Link As String, FileUpload As String, Authenticate As String, Description As String, Params As String, Body As String, Expected As String, InputDisabled As Boolean, DisabledBackground As String, Raw As Boolean)
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	ShowHelpPage
End Sub

Private Sub ShowHelpPage
	#If Debug
	' Generate API Documentation from API Handler Classes
	Dim strContents As String = ReadHandlers(File.DirApp.Replace("\Objects", ""))
	If File.Exists(File.DirApp, "help.html") = False Then
		WebApiUtils.WriteTextFile("help.html", strContents)
	End If
	#Else
	If File.Exists(File.DirApp, "help.html") Then
		Dim strContents As String = File.ReadString(File.DirApp, "help.html")
	End If
	#End If
	Dim strMain As String = WebApiUtils.BuildDocView(WebApiUtils.ReadTextFile("main.html"), strContents)
	' Requires Hasher
	' Store csrf_token inside server session variables
	'Dim HSR As Hasher
	'HSR.Initialize
	'Dim csrf_token As String = HSR.RandomHash2
	'Request.GetSession.SetAttribute(Main.PREFIX & "csrf_token", csrf_token)
	' Append csrf_token into page header. Comment this line to check
	'strMain = WebApiUtils.BuildCsrfToken(strMain, csrf_token)
	strMain = WebApiUtils.BuildTag(strMain, "HELP", "") ' Hide API icon
	strMain = WebApiUtils.BuildHtml(strMain, Main.ctx)
	strMain = WebApiUtils.BuildScript(strMain, $"<script src="${Main.Config.ServerUrl}/assets/scripts/help${IIf(Main.Config.SimpleResponse.Enable, ".simple", "")}.js"></script>"$)
	WebApiUtils.ReturnHtml(strMain, Response)
End Sub

Public Sub ReadHandlers (FileDir As String) As String
	Log(TAB)
	Log("Generating Help page ...")
	Dim verbs(4) As String = Array As String("GET", "POST", "PUT", "DELETE")
	'Dim DocumentedHandlers As List
	'DocumentedHandlers.Initialize
	Dim Handlers As List
	Handlers.Initialize
	Handlers.Add("CategoriesApiHandler")
	Handlers.Add("ProductsApiHandler")
	Handlers.Add("FindApiHandler")
	'For i = 0 To Handlers.Size - 1
	'	Dim TempHandler As String = Handlers.Get(i)
	'	' Avoid duplicate items
	'	If DocumentedHandlers.IndexOf(TempHandler) = -1 Then ' bug 2022-08-29: Section(1) has double quotes
	'		DocumentedHandlers.Add(TempHandler)
	'	End If
	'Next
	Dim strHtml As String
	For Each Handler As String In Handlers 'DocumentedHandlers
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

		Dim HandlerName As String = Handler.Replace("Handler", "")
		HandlerName = HandlerName.Replace("Api", "")
		HandlerName = HandlerName.Replace("Web", "")
		strHtml = strHtml & GenerateHeaderByHandler(HandlerName)
		
		Dim List2 As List
		List2 = File.ReadList(FileDir, Handler & ".bas")
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

										Dim MethodProperties As Map = CreateMap("Verb": verb, "Method": Line2, "Args": Arguments, "Prm": plist, "Body": "&nbsp;", "Noapi": False, "Format": "")
										Methods.Add(MethodProperties)
									Next
								End If
							Next
						Next
					Next
				Else
					' =====================================================================
					' Detect commented hashtags inside Handler
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
					' #authenticate
					'
					' Single keywords:
					' #hide
					' #noapi
					
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
								' Override Handler with name
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Handler", name(1).Trim)
							End If
						End If

						' search for Hide
						If Line3.ToLowerCase.IndexOf("#hide") > -1 Then
							Dim Map3 As Map = Methods.Get(Methods.Size-1)
							Map3.Put("Hide", True)
						End If
						
						' search for Noapi
						If Line3.ToLowerCase.IndexOf("#noapi") > -1 Then
							Dim Map3 As Map = Methods.Get(Methods.Size-1)
							Map3.Put("Noapi", True)
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
						
						' search for Authenticate
						If Line3.ToLowerCase.IndexOf("#authenticate") > -1 Then
							Dim aut() As String
							aut = Regex.Split("=", Line3)
							If aut.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Authenticate", aut(1).Trim)
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
			m.Put("Method", MM(0).Trim)
			If m.ContainsKey("Hide") Then Continue ' Skip Hidden sub
			' Default Handler for singular
			If m.ContainsKey("Handler") = False Then m.Put("Handler", HandlerName)
			strHtml = strHtml & GenerateDocItem(m)
		Next

		' Retain this part for debugging purpose
		'#If DEBUG
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

Private Sub GenerateLink (ApiVersion As String, Handler As String, Elements As List) As String
	Dim Link As String = "$SERVER_URL$/" & Main.Config.ApiName
	If Link.EndsWith("/") = False Then Link = Link & "/"
	If ApiVersion.EqualsIgnoreCase("null") = False Then
		If Main.Config.ApiVersioning Then Link = Link & ApiVersion
		If Link.EndsWith("/") = False Then Link = Link & "/"
	End If
	Link = Link & Handler.ToLowerCase
	For i = 0 To Elements.Size - 1
		Link = Link & "/" & Elements.Get(i)
	Next
	Return Link
End Sub

Private Sub GenerateNoApiLink (Handler As String, Elements As List) As String
	Dim Link As String = "$SERVER_URL$/" & Handler.ToLowerCase
	For i = 0 To Elements.Size - 1
		Link = Link & "/" & Elements.Get(i)
	Next
	Return Link
End Sub

Public Sub GenerateVerbSection (section As VerbSection) As String
	Dim Color As String = section.Color
	Dim Body As String = section.Body
	Dim Link As String = section.Link
	Dim Verb As String = section.Verb
	Dim Params As String = section.Params
	Dim Expected As String = section.Expected
	Dim ElementId As String = section.ElementId
	Dim FileUpload As String = section.FileUpload
	Dim Description As String = section.Description
	Dim Authenticate As String = section.Authenticate
	Dim DisabledBackground As String = section.DisabledBackground
	Dim InputDisabled As Boolean = section.InputDisabled
	Select Color.ToLowerCase
		Case "success"
			Dim BgColor As String = "#d4edda"
		Case "warning"
			Dim BgColor As String = "#fff3cd"
		Case "primary"
			Dim BgColor As String = "#cce5ff"
		Case "danger"
			Dim BgColor As String = "#f8d7da"
	End Select
	Dim strFormat As String
	If section.Raw Then strFormat = "?format=json"
	Dim strBodySample As String
	Dim strBodyInput As String
	Select FileUpload
		Case "Image"
			strBodySample = ""
			strBodyInput = $"File: <label for="file1${ElementId}">Choose an image file:</label><input type="file" id="file1${ElementId}" class="pb-3" name="file1" accept="image/png, image/jpeg, application/pdf">"$
			'strFileUpload = ""
		Case "PDF"
			strBodySample = ""
			strBodyInput = $"File: <label for="file1${ElementId}">Choose a PDF file:</label><input type="file" id="file1${ElementId}" class="pb-3" name="file1" accept="application/pdf">"$
			'strFileUpload = ""
		Case Else
			strBodySample = $"Format: <p class="form-control" style="height: fit-content; background-color: #F0F9FF; font-size: small">${Body}</p>"$
			strBodyInput = $"Body: <textarea id="body${ElementId}" rows="6" class="form-control data-body" style="background-color: #FFFFFF; font-size: small"></textarea></p>"$
			'strFileUpload = ""
	End Select
	Dim strHtml As String = $"
		<button class="collapsible" style="background-color: ${BgColor}"><span class="badge badge-${Color} p-1">${Verb}</span> ${Link}</button>
        <div class="details">
			<div class="row">
				<div class="col-md-6 pt-3">
					${IIf(Authenticate.EqualsIgnoreCase("Basic") Or Authenticate.EqualsIgnoreCase("Token"), _
					$"<span class="badge rounded-pill bg-info text-white px-2 py-1">${WebApiUtils.ProperCase(Authenticate)} Authentication</span><br>"$, "")}
					${Description}
				</div>
			</div>
			<div class="row">
	            <div class="col-md-3 p-3">
					<p><strong>Parameters</strong><br/>
	                <label class="col control-label border rounded" style="padding-top: 5px; padding-bottom: 5px; background-color: #F0F9FF; font-size: small; white-space: pre-wrap;">${Params}</label></p>					
	                ${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), strBodySample, "")}
	            	<p><strong>Status Code</strong><br/>
					${Expected}</p>
				</div>
	            <div class="col-md-3 p-3">
					<form id="form1" method="${Verb}">
					<p><strong>Path</strong><br/>
	                <input${IIf(InputDisabled, " disabled", "")} id="path${ElementId}" class="form-control data-path" style="background-color: ${IIf(InputDisabled, DisabledBackground, "#FFFFFF")}; font-size: small" value="${Link & strFormat}"></p>
					${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), strBodyInput, $""$)}
					<button id="btn${ElementId}" class="${IIf(FileUpload.EqualsIgnoreCase("Image") Or FileUpload.EqualsIgnoreCase("PDF"), $"file"$, $"${Verb.ToLowerCase}"$)}${IIf(Authenticate.ToUpperCase = "BASIC" Or Authenticate.ToUpperCase = "TOKEN", " " & Authenticate.ToLowerCase, "")} button btn-${Color} col-md-6 col-lg-4 p-2 float-right" style="cursor: pointer; padding-bottom: 60px"><strong>Submit</strong></button>
	            	</form>								
				</div>
				<div class="col-md-6 p-3">
					<p><strong>Response</strong><br/>
					<textarea rows="10" id="response${ElementId}" class="form-control" style="background-color: #696969; color: white; font-size: small"></textarea></p>
					<div id="alert${ElementId}" class="alert alert-default" role="alert" style="display: block"></div>
				</div>
			</div>
        </div>"$
	Return strHtml
End Sub

Public Sub GenerateHeaderByHandler (Header As String) As String
	Dim strHtml As String = $"
		<div class="row mt-3">
            <div class="col-md-12">
                <h6 class="text-uppercase text-primary"><strong>${Header}</strong></h6>
            </div>
		</div>"$
	Return strHtml
End Sub

Public Sub GenerateDocItem (Props As Map) As String
	Dim Verb As String = Props.Get("Verb")
	Dim Handler As String = Props.Get("Handler")
	Dim ApiVersion As String = Props.Get("Version")
	Dim Method As String = Props.Get("Method")
	Dim DefaultFormat As String = Props.Get("DefaultFormat")
	Dim Params As List = Props.Get("Prm")
	Dim Elements As List = Props.Get("Elements")
	Dim NoApi As Boolean = Props.Get("Noapi")
	Dim strHTML As String
	Dim strParams As String
	Dim strColor As String
	Dim strLink As String
	Dim strExpected As String = "200 Success"
	Dim strDisabledBackground As String = "#FFFFFF"
	Dim InputDisabled As Boolean
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
		InputDisabled = True
		strDisabledBackground = "#F0F9FF"
	End If
	If Elements.IsInitialized = False Then Elements.Initialize
	If NoApi Then
		strLink = GenerateNoApiLink(Handler, Elements)
	Else
		strLink = GenerateLink(ApiVersion, Handler, Elements)
	End If
	
	Dim section As VerbSection
	section.Initialize
	section.Verb = Verb
	section.Color = strColor
	section.ElementId = Method & Handler
	section.Link = strLink
	section.Raw = DefaultFormat.EqualsIgnoreCase("raw") And Verb = "GET"
	section.FileUpload = Props.Get("FileUpload")
	section.Authenticate = Props.Get("Authenticate")
	section.Description = Props.Get("Desc")
	section.Params = strParams
	section.Body = Props.Get("Body")
	section.Expected = strExpected
	section.InputDisabled = InputDisabled
	section.DisabledBackground = strDisabledBackground
	strHTML = strHTML & GenerateVerbSection(section)
	Return strHTML
End Sub