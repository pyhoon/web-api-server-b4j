B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Help Handler class
' Version 2.00
Sub Class_Globals
	Dim Response As ServletResponse
	Dim DocScripts As String
	Dim blnGenFile As Boolean = True 'ignore
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Response = resp
	ShowHelpPage
End Sub

Private Sub ShowHelpPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("help.html")
	Dim strContents As String
	Dim strScripts As String
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	#if release
	If File.Exists(File.DirApp, "help.html") Then
		strContents = File.ReadString(File.DirApp, "help.html")
		strScripts = File.ReadString(File.DirApp, "help.js")
	End If
	#else
	' Assume only 1 b4j project file
	Dim ProjectFile As String
	Dim ProjectDirFiles As List = File.ListFiles(File.DirApp.Replace("\Objects", ""))
	If ProjectDirFiles.IsInitialized Then
		For Each f As String In ProjectDirFiles
			'Log(f)
			If f.EndsWith(".b4j") Then 
				ProjectFile = f
				Exit
			End If
		Next
	End If
	If ProjectFile = "" Then
		LogError("Unable to find B4J project file!")
		Utility.ReturnHtml($"<h1 style="color: red; text-align: center; margin-top: 30px">Unable to find B4J project file!</h1>"$, Response)
		Return
	End If
	If File.Exists(File.DirApp.Replace("\Objects", ""), ProjectFile) Then
		strContents = ReadProjectFile(File.DirApp.Replace("\Objects", ""), ProjectFile)
		strScripts = DocScripts
	End If
	#End If
	strView = Utility.BuildDocView(strView, strContents)
	strMain = Utility.BuildView(strMain, strView)
	strMain = Utility.BuildHtml(strMain, Main.Config)
	If strScripts.Length > 0 Then
		strScripts = $"<script>
    $(document).ready(function () {
    ${strScripts}
    })
  </script>"$
	Else
		strScripts = ""
	End If
	strMain = Utility.BuildScript(strMain, strScripts)
	Utility.ReturnHtml(strMain, Response)
End Sub
	
Public Sub ReadProjectFile (FileDir As String, FileName As String) As String
	Dim strHtml As String
	Dim strPath As String = File.Combine(FileDir, FileName)
	Log(" ")
	Log("Generating Help page...")
	Log($"Reading project file (${strPath})..."$)
	
	Dim verbs(4) As String = Array As String("GET", "POST", "PUT", "DELETE")
	
	Dim IgnoredHandlers As List
	IgnoredHandlers.Initialize
	'IgnoredHandlers.Add("HelloHandler")
	IgnoredHandlers.Add("HomeHandler")
	IgnoredHandlers.Add("HelpHandler")
	IgnoredHandlers.Add("ConnectHandler")
	IgnoredHandlers.Add("AdminHandler")
	'IgnoredHandlers.Add("DashboardHandler")
	'IgnoredHandlers.Add("FindHandler")
		
	Dim Handlers As List
	Handlers.Initialize
		
	Dim List1 As List
	List1 = File.ReadList(FileDir, FileName)
	For i = 0 To List1.Size - 1
		If List1.Get(i).As(String).Contains("srvr.AddHandler") Then
			Dim Line1 As String = List1.Get(i)
			Dim Section(3) As String = Regex.Split(",", Line1)
			' 2022-05-11: bug (fixed) blank space before ' not trimmed
			If Section(0).Trim.StartsWith("'") Then
				'Log("Commented line: " & Section(1))
			Else
				Dim TempHandlerName As String = Section(1).Trim.Replace($"""$, "")
				If IgnoredHandlers.IndexOf(TempHandlerName) = -1 Then
					' Avoid duplicate items
					If Handlers.IndexOf(TempHandlerName) = -1 Then ' bug 2022-08-29: Section(1) has double quotes
						Handlers.Add(TempHandlerName)
					End If
				End If
			End If
		End If
	Next
			
	For Each HandlerFile In Handlers
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

		'strHtml = strHtml & GenerateHeaderByHandler (HandlerFile.As(String).Replace("Handler", ""))
		Dim HandlerName As String = HandlerFile.As(String).Replace("Handler", "")
		strHtml = strHtml & GenerateHeaderByHandler(HandlerName)
		
		Dim List2 As List
		List2 = File.ReadList(FileDir, HandlerFile & ".bas")

		Dim Literals() As String
		
		For i = 0 To List2.Size - 1
			If List2.Get(i).As(String).StartsWith("'") Or List2.Get(i).As(String).StartsWith("#") Then
				' Ignore the line
			Else
				Dim index As Int = List2.Get(i).As(String).ToLowerCase.IndexOf("sub")
				If index > -1 Then
					Dim Line2 As String = List2.Get(i).As(String).SubString(index).Replace("Sub", "").Trim
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

										'Dim MethodProperties As Map = CreateMap("Verb": verb, "Method": Line2, "Args": Arguments, "Prm": plist, "Body": "&nbsp;", "PLURAL": False, "DESC1": "", "DESC2": "(N/A)", "Elems": 1)
										Dim MethodProperties As Map = CreateMap("Verb": verb, "Method": Line2, "Args": Arguments, "Prm": plist, "Body": "&nbsp;", "Plural": False, "Format": "")
										Methods.Add(MethodProperties)
									Next
								End If
							Next
						Next
					Next
				Else
					Dim Line3 As String = List2.Get(i).As(String)
				
					' Try get the Literals
					If Line3.ToLowerCase.Replace(" ", "").IndexOf("literals()asstring") > -1 Then
						Dim ps As Int = Line3.LastIndexOf("(") ' ps = index of last open parentheses, note: literal should not contain '(' character
						Dim pe As Int = Line3.LastIndexOf(")") ' pe = index of last close parentheses, just in case ) is not end character
						Dim strLiterals As String = Line3.SubString2(ps+1, pe)
						Literals = Regex.Split(",", strLiterals)
						' Clean up unwanted characters
						For e = 0 To Literals.Length - 1
							Literals(e) = Literals(e).Replace($"""$, "").Trim
						Next
					End If
				
					If Line3.IndexOf("'") > -1 Then
						' search for Body
						If Line3.ToLowerCase.IndexOf("#body") > -1 Then
							Dim body() As String
							body = Regex.Split("=", Line3)
							If body.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("Body", body(1).Trim)
							End If
						End If
						' search for Action
						If Line3.ToLowerCase.IndexOf("#action") > -1 Then
							Dim act() As String
							act = Regex.Split("=", Line3)
							If act.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("ACTION", act(1).Trim)
							End If
						End If
						' search for plural keyword						
						If Line3.ToLowerCase.IndexOf("#plural") > -1 Then
							Dim Map3 As Map = Methods.Get(Methods.Size-1)
							Map3.Put("Plural", True)
						End If
						' search for raw keyword
						If Line3.ToLowerCase.IndexOf("#defaultformat") > -1 Then
							'Dim Map3 As Map = Methods.Get(Methods.Size-1)
							'Map3.Put("RAW", True)													
							Dim fmt() As String
							fmt = Regex.Split("=", Line3)
							If fmt.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								If fmt(1).Trim = "raw" Then
									Map3.Put("Format", "raw")
								'Else
								'	Map3.Put("Format", fmt(1).Trim)
								End If								
							End If
						End If
						' search for Desc
						If Line3.ToLowerCase.IndexOf("#desc") > -1 Then
							Dim desc() As String
							desc = Regex.Split("=", Line3)
							If desc.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Map3.Put("DESC", desc(1).Trim)
							End If
						End If
						' search for Desc1
						'If Line3.ToLowerCase.IndexOf("#desc1") > -1 Then
						'	Dim dc1() As String
						'	dc1 = Regex.Split("=", Line3)
						'	If dc1.Length = 2 Then
						'		Dim Map3 As Map = Methods.Get(Methods.Size-1)
						'		Map3.Put("DESC1", dc1(1).Trim)
						'	End If
						'End If
						' search for Desc2
						'If Line3.ToLowerCase.IndexOf("#desc2") > -1 Then
						'	Dim dc2() As String
						'	dc2 = Regex.Split("=", Line3)
						'	If dc2.Length = 2 Then
						'		Dim Map3 As Map = Methods.Get(Methods.Size-1)
						'		Map3.Put("DESC2", dc2(1).Trim)
						'	End If
						'End If
						' Get # of elements in URL
						'If Line3.ToLowerCase.IndexOf("#elems") > -1 Then
						'	Dim elems() As String
						'	elems = Regex.Split("=", Line3)
						'	If elems.Length = 2 Then
						'		Dim Map3 As Map = Methods.Get(Methods.Size-1)
						'		Map3.Put("Elems", elems(1).Trim)
						'	End If
						'End If
						' Elements List
						If Line3.ToLowerCase.IndexOf("#elements") > -1 Then
							Dim Elements() As String
							Elements = Regex.Split("=", Line3)
							If Elements.Length = 2 Then
								Dim Map3 As Map = Methods.Get(Methods.Size-1)
								Dim List3 As List = Elements(1).Trim.As(JSON).ToList
								'List3.Initialize
								'Elements(1).Trim.As(JSON).ToList
								'Map3.Put("Elements", Elements(1).Trim)
								Map3.Put("Elements", List3)
							End If
						End If
					End If
				End If
			End If
		Next
				
		For Each m As Map In Methods
			Dim MM(2) As String
			MM = Regex.Split(" As ", m.Get("Method")) ' Ignore return type
			'strHtml = strHtml & GenerateDocItem(m.Get("Verb"), MM(0).Trim, m.Get("Prm"), m.Get("Body"), m.Get("DESC1"), m.Get("DESC2"), Literals, m.Get("Elems"))
			'strHtml = strHtml & GenerateDocItem(HandlerName, m.Get("Verb"), MM(0).Trim, m.Get("Prm"), m.Get("Body"), m.Get("ACTION"), m.Get("PLURAL"), m.Get("DESC1"), m.Get("DESC2"), Literals, m.Get("Elements"))
			strHtml = strHtml & GenerateDocItem(HandlerName, m.Get("Verb"), MM(0).Trim, m.Get("Prm"), m.Get("Body"), m.Get("ACTION"), m.Get("Plural"), m.Get("Format"), m.Get("DESC"), Literals, m.Get("Elements"))
		Next

		' Retain this part for debugging purpose
		'For Each m As Map In Methods
		'	Log(" ")
		'	Log("[" & m.Get("Verb") & "]")
		'	Log(m.Get("Method"))
		'	Dim MM(2) As String
		'	MM = Regex.Split(" As ", m.Get("Method")) ' Ignore return type
		'	Log("(Trimmed) " & MM(0).Trim)
		'	Dim Lst As List
		'	Lst.Initialize
		'	Lst = m.Get("Prm")
		'	For i = 0 To Lst.Size - 1
		'		'Log("(" & i & ") " & Lst.Get(i))
		'		Dim pm() As String
		'		pm = Regex.Split(" as ", Lst.Get(i).As(String).ToLowerCase)
		'		Log(pm(0).Trim & " [" & pm(1).Trim & "]")
		'	Next
		'	Log("DESC1: " & m.Get("DESC1"))
		'	Log("DESC2: " & m.Get("DESC2"))
		'Next
	Next
	
	#if debug
	' Save these files for Release/Production
	If blnGenFile Then
		If File.Exists(File.DirApp, "help.html") Then File.Delete(File.DirApp, "help.html")
		If File.Exists(File.DirApp, "help.js") Then File.Delete(File.DirApp, "help.js")
		Utility.WriteTextFile("help.html", strHtml)
		Utility.WriteTextFile("help.js", DocScripts)
	End If
	#End If
	Log($"Help page has been generated."$)
	Return strHtml
End Sub

'Public Sub GenerateActionLink (Literals() As String, Elems As Int, Action As String) As String
'	Dim Link As String = Main.ROOT_PATH
'	If Elems > 0 And Literals.Length > 0 Then
'		Link = Link & Literals(0)
'		If Elems > 1 Then
'			If Action <> "" Then
'				Link = Link & "/" & Action
'			Else
'				Link = Link & "/" & Literals(1)
'			End If
'		End If
'		If Elems = 3 Then
'			Link = Link & "/" & Literals(2)
'		End If
'	End If
'	Return Link
'End Sub

Private Sub GenerateLink (Literals() As String, Elements As List, IsPlural As Boolean) As String
	Dim Link As String = Main.ROOT_PATH & Main.API_PATH
	'Dim Link As String = Main.API_PATH 'Main.ROOT_PATH
	'If Elems > 0 And Literals.Length > 0 Then
	'If Elems Mod 2 = 0 Then
	'	Elems = Elems - 1 ' Elems = 2 is same as Elems = 1, Elems = 4 is same as Elems = 3
	'End If
	If IsPlural Then
		Link = Link & Literals(0)
	Else
		Link = Link & Literals(1)
	End If
	'If Elems > 2 Then
	'	Link = Link & "/" & Literals(2) & "/" & Literals(2)
	'End If
	'If ID.Size > 0 Then
	'	'Link = Link & "/" & Literals(Elems)
	'	Link = Link & "/" & Literals(3)
	'End If
	'For Each param As String In ID.Keys
	'	Link = Link & "/" & Literals(3)
	'Next
	For i = 0 To Elements.Size - 1
		Link = Link & "/" & Elements.Get(i)
	Next
	'End If
	Return Link
End Sub

'Private Sub GenerateLink1 (Literals() As String, Elems As Int) As String
'	Dim Link As String = Main.ROOT_PATH
'	If Elems > 0 And Literals.Length > 0 Then
'		If Elems Mod 2 = 0 Then
'			Elems = Elems - 1
'		End If
'		Link = Link & Literals(0)
'		If Elems > 2 Then
'			Dim keywords() As String
'			keywords = Regex.Split("\|", Literals(1))
'			Link = Link & "/" & keywords(0) & "/" & Literals(2) & "/" & Literals(Elems)
'		End If
'	End If
'	Return Link
'End Sub

'Private Sub GenerateLink2 (Literals() As String, Elems As Int) As String
'	Dim Link As String = Main.ROOT_PATH
'	If Elems > 0 And Literals.Length > 0 Then
'		If Elems Mod 2 = 0 Then
'			Elems = Elems - 1
'		End If
'		Link = Link & Literals(0)
'		If Elems > 2 Then
'			Dim keywords() As String
'			keywords = Regex.Split("\|", Literals(1))
'			Link = Link & "/" & keywords(1) & "/" & Literals(2) & "/" & Literals(Elems)
'		End If
'	End If
'	Return Link
'End Sub

Public Sub GenerateResponseScript (Verb As String, btnButtonId As String) As String
	Dim strHeaders As String
	Select Main.AUTHENTICATION_TYPE.ToUpperCase
		Case "JSON WEB TOKEN AUTHENTICATION"
			strHeaders = $"
		  headers: {
		  	"Accept": "application/json",
		    "Authorization": localStorage.getItem('access_token')
		  },"$
		Case "TOKEN AUTHENTICATION"
			strHeaders = $"
		  headers: {
		  	"Accept": "application/json",
		    "Authorization": localStorage.getItem('access_token')
		  },"$
		Case "BASIC AUTHENTICATION"
			' todo: temporary hard code for Documentation/Help App
			Main.CLIENT_ID = "WebAPI200"
			Main.CLIENT_SECRET = "45D1CE22-650D-9A0E-6338-90C83BFB934F"
			If Main.CLIENT_ID.Length > 0 And Main.CLIENT_SECRET.Length > 0 Then
				strHeaders = $"
		  headers: {
		  	"Accept": "application/json",
		    "Authorization": "Basic " + btoa("${Main.CLIENT_ID}" + ":" + "${Main.CLIENT_SECRET}")
		  },"$
			End If
		Case Else
		'	
	End Select	
	Dim strScript As String = $"  $("#${btnButtonId}").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "${Verb}",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
		  ${strHeaders}
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, textStatus, thrownError) {
            $("#alert" + id).html(xhr.status + ' ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
"$
	Return strScript
End Sub

Public Sub GenerateVerbSection (Verb As String, strColor As String, strButtonID As String, strLink As String, blnRaw As Boolean, strDesc As String, strParams As String, strBody As String, strExpected As String, strInputDisabled As String, strDisabledBackground As String) As String
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
	Dim strHtml As String = $"
		<button class="collapsible" style="background-color: ${strBgColor}"><span class="badge badge-${strColor} p-1">${Verb}</span> ${strLink}</button>
        <div class="details">
			<div class="row">
	            <div class="col-md-3 p-3">
	                <p>${strDesc}</p>
					<p><strong>Parameters</strong><br/>
	                Path: <label class="form-control" style="background-color: #F0F9FF; font-size: small">${strParams}</label></p>					
	                ${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), $"Body: <p class="form-control" style="height: fit-content; background-color: #F0F9FF; font-size: small">${strBody}</p>"$, $""$)}					
					<p><strong>Response</strong><br/>
	                ${strExpected}</p>
	            </div>
	            <div class="col-md-3 p-3">
					<p>&nbsp;</p>
	                <p></p>
					<form id="form1" method="${Verb}">
					<p><strong>Parameters</strong><br/>
	                Path: <input ${strInputDisabled} id="path${strButtonID}" class="form-control data-path" style="background-color: ${IIf(strInputDisabled.EqualsIgnoreCase("disabled"), strDisabledBackground, "#FFFFFF")}; font-size: small" value="${strLink & strFormat}"></p>	                
					${IIf(Verb.EqualsIgnoreCase("POST") Or Verb.EqualsIgnoreCase("PUT"), $"Body: <textarea id="body${strButtonID}" rows="6" class="form-control data-body" style="background-color: #FFFFFF; font-size: small"></textarea></p>"$, $""$)}					
	                <button id="${strButtonID}" class="button btn-${strColor} col-md-6 col-lg-4 p-2 float-right" style="cursor: pointer; padding-bottom: 60px"><strong>Submit</strong></button>
	            	</form>								
				</div>
				<div class="col-md-6 p-3">
					<p>&nbsp;</p>
					<p><strong>Response</strong>
					<br/>					
					<textarea rows="10" id="response${strButtonID}" class="form-control" style="background-color: #696969; color: white; font-size: small"></textarea></p>
					<div id="alert${strButtonID}" class="alert alert-default" role="alert" style="display: block"></div>
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

'Public Sub GenerateDocItem (Verb As String, MethodName As String, Params As List, Body As String, Desc1 As String, Desc2 As String, Literals() As String, Elems As Int) As String
'Public Sub GenerateDocItem (Controller As String, Verb As String, MethodName As String, Params As List, Body As String, Action As String, Plural As Boolean, Desc1 As String, Desc2 As String, Literals() As String, Elements As List) As String
Public Sub GenerateDocItem (Controller As String, Verb As String, MethodName As String, Params As List, Body As String, Action As String, Plural As Boolean, DefaultFormat As String, Desc As String, Literals() As String, Elements As List) As String
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
			strExpected = strExpected & "<br/>404 Not Found"
		Case "POST"			
			strColor = "warning"
			strExpected = "201 Created"
		Case "PUT"
			strColor = "primary"
			strExpected = strExpected & "<br/>404 Not Found"
		Case "DELETE"
			strColor = "danger"
			strExpected = strExpected & "<br/>404 Not Found"
	End Select
	' Add other expected response
	strExpected = strExpected & "<br/>400 Bad Request"
	strExpected = strExpected & "<br/>422 Error Execute Query"
	
	' Ignore Method name
	'Log(MethodName)
	'	If Action <> "null" Then
	'		If Params.Size > 0 And Params.Get(0).As(String).Length > 0 Then
	'			For i = 0 To Params.Size - 1
	'				Dim pm() As String
	'				pm = Regex.Split(" As ", Params.Get(i))
	'				strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]" & "<br/>"
	'			Next
	'		Else
	'			strParams = "Not required"
	'			strInputDisabled = "disabled"
	'		End If
	'		strLink = GenerateActionLink(Literals, Elems, Action)
	'		If Verb = "GET" Then strLink = strLink & "?format=json"
	'		'Log(strLink)
	'		strHTML = GenerateVerbSection(Verb, strColor, "btn" & MethodName, strLink, Desc1, strParams, Body, strExpected, strInputDisabled, strDisabledBackground)
	'		DocScripts = DocScripts & GenerateResponseScript(Verb, "btn" & MethodName)
	'		'DocScripts = DocScripts & GenerateResponseScript(Verb, "btn" & MethodName, strLink.Contains("upload"))
	'		Return strHTML
	'	End If
	
	'If Desc1 <> "(N/A)" Then
	'	If Params.Size > 0 And Params.Get(0).As(String).Length > 0 Then
	'		For i = 0 To Params.Size - 1
	'			Dim pm() As String
	'			pm = Regex.Split(" As ", Params.Get(i))
	'			strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]" & "<br/>"
	'		Next
	'	Else
	'		strParams = "Not required"
	'		strInputDisabled = "disabled"
	'	End If
	'
	'	' To special handle FindHandler
	'	'If Literals(1).Contains("|") Then
	'	'	strLink = GenerateLink1(Literals, Elems)
	'	'Else
	'	strLink = GenerateLink(Literals, Elements, Plural)
	'	'End If
	'	strHTML = GenerateVerbSection(Verb, strColor, "btn" & MethodName & "1", strLink, Desc1, strParams, Body, strExpected, strInputDisabled, strDisabledBackground)
	'	DocScripts = DocScripts & GenerateResponseScript(Verb, "btn" & MethodName & "1")
	'End If
	
	'strParams = ""
	''strExpected = "200 Success"
	'strInputDisabled = ""
	'strDisabledBackground = "#FFFFFF"
	
	'If Desc2 <> "(N/A)" Then
	'	' To special handle FindHandler
	'	'		If Literals(1).Contains("|") Then
	'	'			If Params.Size > 1 Then
	'	'				For i = 0 To Params.Size - 1
	'	'					Dim pm() As String
	'	'					pm = Regex.Split(" As ", Params.Get(i))
	'	'					strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]" & "<br/>"
	'	'				Next
	'	'			Else If Params.Size > 0 Then
	'	'				If Elems > 2 Then
	'	'					Dim pm() As String
	'	'					pm = Regex.Split(" As ", Params.Get(0))
	'	'					strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]"
	'	'				Else
	'	'					strParams = "Not required"
	'	'					strInputDisabled = "disabled"
	'	'					strDisabledBackground = "#FFFF99"
	'	'				End If
	'	'			Else
	'	'				strParams = "Not required"
	'	'				strInputDisabled = "disabled"
	'	'				strDisabledBackground = "#FFFF99"
	'	'			End If
	'	'			strLink = GenerateLink2(Literals, Elems)
	'	'		Else
	'	If Params.Size > 1 Then
	'		For i = 0 To Params.Size - 2
	'			Dim pm() As String
	'			pm = Regex.Split(" As ", Params.Get(i))
	'			strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]" & "<br/>"
	'		Next
	'		'Else If Params.Size > 0 Then
	'		'	If Elems > 2 Then
	'		'		Dim pm() As String
	'		'		pm = Regex.Split(" As ", Params.Get(0))
	'		'		strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]"
	'		'	Else
	'		'		strParams = "Not required"
	'		'		strInputDisabled = "disabled"
	'		'		strDisabledBackground = "#FFFF99"
	'		'	End If
	'	Else If Params.Size = 1 Then
	'		Dim pm() As String
	'		pm = Regex.Split(" As ", Params.Get(0))
	'		strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]"
	'	Else
	'		strParams = "Not required"
	'		strInputDisabled = "disabled"
	'		strDisabledBackground = "#FFFF99"
	'	End If
	'	strLink = GenerateLink(Literals, False, Plural)
	'	'End If
	'	strHTML = strHTML & GenerateVerbSection(Verb, strColor, "btn" & MethodName & "2", strLink, Desc2, strParams, Body, strExpected, strInputDisabled, strDisabledBackground)
	'	DocScripts = DocScripts & GenerateResponseScript(Verb, "btn" & MethodName & "2")
	'End If
	
	'If Desc <> "(N/A)" Then
	'If Params.Size > 1 Then
	'	For i = 0 To Params.Size - 2
	'		If i > 0 Then strParams = strParams & "<br/>"
	'		Dim pm() As String
	'		pm = Regex.Split(" As ", Params.Get(i))
	'		strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]" '& "<br/>"
	'	Next
	'Else If Params.Size = 1 Then
	'	Dim pm() As String
	'	pm = Regex.Split(" As ", Params.Get(0))
	'	strParams = strParams & pm(0).Trim & " [" & pm(1).Trim & "]"

	If Params.Size > 0 Then
		For i = 0 To Params.Size - 1
			If i > 0 Then strParams = strParams & "<br/>"
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
	strLink = GenerateLink(Literals, Elements, Plural)
	'If Format.EqualsIgnoreCase("raw") And Verb = "GET" Then strLink = strLink & "?format=raw"
	'If DefaultFormat.EqualsIgnoreCase("raw") And Verb = "GET" Then strLink = strLink & "?format=json"
	If DefaultFormat.EqualsIgnoreCase("raw") And Verb = "GET" Then blnRaw = True
	'End If
	strHTML = strHTML & GenerateVerbSection(Verb, strColor, "btn" & Controller & MethodName, strLink, blnRaw, Desc, strParams, Body, strExpected, strInputDisabled, strDisabledBackground)
	DocScripts = DocScripts & GenerateResponseScript(Verb, "btn" & Controller & MethodName)
	'End If
	
	Return strHTML
End Sub