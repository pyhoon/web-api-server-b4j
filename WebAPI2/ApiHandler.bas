B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Api Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Elements() As String
	Private Method As String
	Private HRM As HttpResponseMessage
End Sub

Public Sub Initialize
	HRM.Initialize
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
	Elements = Utility.GetUriElements(Request.RequestURI)
	If ElementLastIndex < Main.Element.ApiControllerIndex Then
		Utility.ReturnBadRequest(Response)
		Return
	End If

	Dim ApiVersionIndex As Int = Main.Element.ApiVersionIndex
	Dim ApiVersionElement As String = Elements(ApiVersionIndex)
	Dim ControllerIndex As Int = Main.Element.ApiControllerIndex
	Dim ControllerElement As String = Elements(ControllerIndex)
	If ElementLastIndex > Main.Element.ApiControllerIndex Then
		Dim FirstIndex As Int = Main.Element.ApiControllerIndex + 1
		Dim FirstElement As String = Elements(FirstIndex)
	End If
	
	Select ControllerElement
		Case "categories"
			Dim Category As CategoryController
			Category.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Utility.ReturnHttpResponse(Category.GetCategories, Response)
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "category"
			Dim Category As CategoryController
			Category.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = FirstIndex Then
						If Utility.CheckInteger(FirstElement) = False Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						End If
						Utility.ReturnHttpResponse(Category.GetCategory(FirstElement), Response)
						Return
					End If
				Case "POST"
					If ElementLastIndex = ControllerIndex Then
						Utility.ReturnHttpResponse(Category.PostCategory, Response)
						Return
					End If
				Case "PUT"
					If ElementLastIndex = FirstIndex Then
						If Utility.CheckInteger(FirstElement) = False Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						End If
						Utility.ReturnHttpResponse(Category.PutCategory(FirstElement), Response)
						Return
					End If
				Case "DELETE"
					If ElementLastIndex = FirstIndex Then
						If Main.AUTHENTICATION_TYPE = "JSON WEB TOKEN AUTHENTICATION" Then
							' Let's try Validate action with Token
							If ValidateToken Then
								If Utility.CheckInteger(FirstElement) = False Then
									Utility.ReturnErrorUnprocessableEntity(Response)
									Return
								End If
								Utility.ReturnHttpResponse(Category.DeleteCategory(FirstElement), Response)
								Return
							End If
						Else
							Utility.ReturnHttpResponse(Category.DeleteCategory(FirstElement), Response)
							Return
						End If
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "posts"
			Dim Post As PostController
			Post.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = ControllerIndex Then
						Utility.ReturnHttpResponse(Post.GetPosts, Response)
						Return
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "post"
			Dim Post As PostController
			Post.Initialize(Request, Response)
			Select Method
				Case "GET"
					If ElementLastIndex = FirstIndex Then
						If Utility.CheckInteger(FirstElement) = False Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						End If
						Utility.ReturnHttpResponse(Post.GetPost(FirstElement), Response)
						Return
					End If
				Case "POST"
					If ElementLastIndex = ControllerIndex Then
						Utility.ReturnHttpResponse(Post.PostPost, Response)
						Return
					End If
				Case "PUT"
					If ElementLastIndex = FirstIndex Then
						If Utility.CheckInteger(FirstElement) = False Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						End If
						Utility.ReturnHttpResponse(Post.PutPost(FirstElement), Response)
						Return
					End If
				Case "DELETE"
					If ElementLastIndex = FirstIndex Then
						If Utility.CheckInteger(FirstElement) = False Then
							Utility.ReturnErrorUnprocessableEntity(Response)
							Return
						End If
						Utility.ReturnHttpResponse(Post.DeletePost(FirstElement), Response)
						Return
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
					' Get User Account
					If ElementLastIndex = ControllerIndex Then
						Utility.ReturnHttpResponse(Account.GetAccount, Response)
						Return
					End If
					If ElementLastIndex = FirstIndex Then
						Select FirstElement
							Case "token"
								If Main.AUTHENTICATION_TYPE <> "JSON WEB TOKEN AUTHENTICATION" Then
									'Utility.ReturnError("JSON Web Token is not set", 500, Response)
									HRM.ResponseCode = 500
									HRM.ResponseError = "JSON Web Token is not set"
									Utility.ReturnHttpResponse(HRM, Response)
									Return
								End If
								' Get User access token using refresh token from cookie
								Utility.ReturnHttpResponse(Account.GetToken, Response)
								Return
						End Select
					End If
				Case "POST"
					If ElementLastIndex = FirstIndex Then
						Select FirstElement
							Case "register"
								Utility.ReturnHttpResponse(Account.PostRegister, Response)
								Return
							Case "login"
								Utility.ReturnHttpResponse(Account.PostLogin, Response)
								Return
							Case "token"
								If Main.AUTHENTICATION_TYPE <> "JSON WEB TOKEN AUTHENTICATION" Then
									'Utility.ReturnError("JSON Web Token is not set", 500, Response)
									HRM.ResponseCode = 500
									HRM.ResponseError = "JSON Web Token is not set"
									Utility.ReturnHttpResponse(HRM, Response)
									Return
								End If
								' Get User access token using refresh token from cookie
								If ElementLastIndex = ControllerIndex Then
									Utility.ReturnHttpResponse(Account.PostToken, Response)
									Return
								End If
						End Select
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "password"
			Dim Password As PasswordController
			Password.Initialize(Request, Response)
			Select Method
				'Case "GET"
				'	' Get User Password
				'	If ElementLastIndex = ControllerIndex Then
				'		Utility.ReturnHttpResponse(Password.GetPassword, Response)
				'		Return
				'	End If
				Case "POST"
					If ElementLastIndex = FirstIndex Then
						Select FirstElement
							Case "change"
								Utility.ReturnHttpResponse(Password.PostChangePassword, Response)
								Return
							Case "forgot"
								Utility.ReturnHttpResponse(Password.PostForgotPassword, Response)
								Return
						End Select
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "hello"
			Select Method
				Case "GET"
					Dim Hello As HelloController
					Hello.Initialize(Response)
					If Main.Element.Api.Versioning Then
						Select ElementLastIndex
							Case ControllerIndex
								Select ApiVersionElement
									Case "dev"
										Hello.GetShowHelloWorldV1
										Return
									Case "live"
										Hello.GetShowHelloWorld
										Return
								End Select
							Case FirstIndex
								Select ApiVersionElement
									Case "v1"
										Hello.GetShowMessageV1(FirstElement)
										Return
									Case "v2"
										Hello.GetShowMessage(FirstElement)
										Return
								End Select
						End Select
					Else
						Select ElementLastIndex
							Case ControllerIndex
								Hello.GetShowHelloWorld
								Return
							Case FirstIndex
								Hello.GetShowMessage(FirstElement)
								Return
						End Select
					End If
				Case Else
					Utility.ReturnMethodNotAllow(Response)
					Return
			End Select
		Case "home"
			Select Method
				Case "GET"
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
		Case Else

	End Select
	Utility.ReturnBadRequest(Response)
End Sub

' Validate Client using access token for specific API
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