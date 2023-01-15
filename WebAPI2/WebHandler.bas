B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Web Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Elements() As String
	Private Method As String
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	Method = Request.Method.ToUpperCase
	ProcessRequest
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Private Sub ProcessRequest
	'Log(Request.RequestURI)
	Elements = Utility.GetUriElements(Request.RequestURI)

	' Home Page
	If ElementLastIndex < Main.Element.WebControllerIndex Then
		Select Method
			Case "GET"
				ProcessHomepage
				Return
			Case "POST"
				Dim keywords As String = Request.GetParameter("keywords")
				Dim Home As HomeController
				Home.Initialize(Response)
				Home.Search(keywords)
				Return
			Case Else
				Utility.ReturnMethodNotAllow(Response)
				Return
		End Select
	End If
	
	' Controllers
	Dim ControllerIndex As Int = Main.Element.WebControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	If ElementLastIndex > Main.Element.WebControllerIndex Then
		Dim FirstIndex As Int = Main.Element.WebControllerIndex + 1
		Dim FirstElement As String = Elements(FirstIndex)
		If ElementLastIndex > Main.Element.WebControllerIndex + 1 Then
			Dim SecondIndex As Int = Main.Element.WebControllerIndex + 2
			Dim SecondElement As String = Elements(SecondIndex)
		End If
	End If
	Select ControllerElement
		Case "category"
			Dim Category As CategoryController
			Category.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Category.ShowPage
						Return
					End If
					If ElementLastIndex = SecondIndex Then
						Select FirstElement
							Case "sort"
								Utility.ReturnHttpResponse(Category.GetCategoriesSortedby(SecondElement), Response)
								Return
						End Select
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "account"
			Dim Account As AccountController
			Account.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Account.ShowAccountPage
						Return
					End If
					If ElementLastIndex = FirstIndex Then
						Select FirstElement
							Case "activate" ' activation code not provided
								Utility.ReturnErrorUnprocessableEntity(Response)
								Return
						End Select
					End If
					If ElementLastIndex = SecondIndex Then
						Select FirstElement
							Case "activate"
								Account.GetActivate(SecondElement)
								Return
						End Select
					End If
				Case "POST"
					If ElementLastIndex = FirstIndex Then
						Select FirstElement
							Case "login"
								Log(Account.SessionLogin) ' for session based authentication
								Return
						End Select
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "change-password"
			'Log(ControllerElement)
			Dim Password As PasswordController
			Password.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Password.ShowChangePasswordPage
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "forgot-password"
			Log(ControllerElement)
			Dim Password As PasswordController
			Password.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Password.ShowForgotPasswordPage
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "confirm-reset-password"
			Log(ControllerElement)
			Dim Password As PasswordController
			Password.Initialize(Request, Response)
			Select Method
				Case "GET"
					Dim Format As String = Request.GetParameter("format")
					If ElementLastIndex = ControllerIndex Then ' reset code not provided
						If Format.EqualsIgnoreCase("json") Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						Else
							Dim strMessage As String = $"<h1>Invalid Reset Code</h1><p>Please contact system admin at ${Main.Config.Get("ADMIN_EMAIL")}</p>"$
							Utility.ReturnHtml(strMessage, Response)
							Return
						End If
					End If
					If ElementLastIndex = FirstIndex Then
						Password.GetResetPassword(FirstElement)
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "register"
			Log(ControllerElement)
			Dim Account As AccountController
			Account.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Account.ShowRegisterPage
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "login"
			Dim Account As AccountController
			Account.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						If Main.SESSIONS_ENABLED Then
							Dim sessionId As String = Request.GetSession.GetAttribute2(Main.PREFIX & "sessionId", "")
							If sessionId.Length > 0 Then
								Utility.ReturnLocation(Main.ROOT_PATH & "dashboard", Response)
								Return
							End If
						End If						
						Account.ShowLoginPage
						Return
					End If
				Case "POST"
					Log(Account.SessionLogin)
					Return
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "logout"
			Dim Account As AccountController
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Account.Initialize(Request, Response)
						Account.SessionLogout
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select			
		Case "dashboard"
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Dim Account As AccountController
						Account.Initialize(Request, Response)
						If Main.SESSIONS_ENABLED Then
							Dim sessionId As String = Request.GetSession.GetAttribute2(Main.PREFIX & "sessionId", "")
							If sessionId.Length > 0 Then
								Account.ShowDashboardPage
								Return
							Else
								Utility.ReturnLocation(Main.ROOT_PATH & "login", Response)
								Return
							End If
						End If
						Account.ShowDashboardPage
						Return
					End If					
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "starter"
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Dim Account As AccountController
						Account.Initialize(Request, Response)
						If Main.SESSIONS_ENABLED Then
							Dim sessionId As String = Request.GetSession.GetAttribute2(Main.PREFIX & "sessionId", "")
							If sessionId.Length > 0 Then
								Account.ShowStarterPage
								Return
							Else
								Utility.ReturnLocation(Main.ROOT_PATH & "login", Response)
								Return
							End If
						End If
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "connect"
			Select Method
				Case "GET"
					' Controller not required
					Utility.ReturnSimpleConnect("List", Response)
					Return
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
			'Case "hello"
			'	Log(ControllerElement)
		Case Else
				
	End Select
	Utility.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ProcessHomepage
	Dim Home As HomeController
	Home.Initialize(Response)
	' Search e.g. ' http://127.0.0.1:19800/v1/?search=ha
	Dim keywords As String = Request.GetParameter("search") ' GET
	If keywords <> "" Then
		Home.Search(keywords)
		Return
	End If
					
	Dim default As String = Request.GetParameter("default")  ' GET
	If default <> "" Then
		Home.Search("")
		Return
	End If

	Home.ShowHomePage
End Sub