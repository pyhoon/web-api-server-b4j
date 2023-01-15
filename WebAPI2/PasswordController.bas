B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Password Controller class
' Version 2.00
' Additional Modules: Utility, MiniORM, JSONWebToken
' Additional Libraries: jNet, jServer, jSQL
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private HRT As HttpResponseContent
End Sub

Public Sub Initialize (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	HRM.Initialize
	HRT.Initialize
End Sub

Public Sub ShowChangePasswordPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("change-password.html")
	strMain = Utility.BuildView(strMain, strView)
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	' Method 1: Use hard coded js
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.password.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	
	' Method 2: Use js with template
	'Dim strScript As String = Utility.ReadTextFile("password.js")
	'strMain = Utility.BuildScript2(strMain, strScript, Main.Config)
	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Utility.ReturnHtml(strMain, Response)
End Sub

' Forgot my password
Public Sub ShowForgotPasswordPage
	Dim strMain As String = Utility.ReadTextFile("main.html")
	Dim strView As String = Utility.ReadTextFile("forgot-password.html")
	strMain = Utility.BuildView(strMain, strView)
	
	' Show Server Time
	Main.SERVER_TIME = Main.DB.ReturnDateTime(Main.TIMEZONE)
	Main.Config.Put("SERVER_TIME", Main.SERVER_TIME)
	
	' Method 1: Use hard coded js
	Dim strScripts As String = $"<script src="${Main.ROOT_URL}/assets/js/webapi.password.js"></script>"$
	strMain = Utility.BuildScript(strMain, strScripts)
	
	' Method 2: Use js with template
	'Dim strScript As String = Utility.ReadTextFile("password.js")
	'strMain = Utility.BuildScript2(strMain, strScript, Main.Config)
	
	strMain = Utility.BuildHtml(strMain, Main.Config)
	Utility.ReturnHtml(strMain, Response)
End Sub

Public Sub PostChangePassword As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Change password
	' #Elements = ["change"]
	' #Body = {<br>&nbsp; "email": "user_email",<br>&nbsp; "current": "current_password",<br>&nbsp; "new": "new_password"<br>&nbsp; "repeat": "repeat_password"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_email As String = data.Get("email")
			Dim old_password As String = data.Get("current")
			Dim new_password As String = data.Get("new")
			Dim repeat_password As String = data.Get("repeat")
			If user_email = "" Or old_password = "" Or new_password = "" Or repeat_password = "" Then
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Please Fill In All Fields"
				Return HRM
			End If
			If new_password <> repeat_password Then
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Password Not Matched"
				Return HRM
			End If
			If old_password = new_password Then
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "New Password Cannot Same to Current Password"
				Return HRM
			End If
			
			strSQL = Main.DB.Queries.Get("SELECT_USER_SALT_BY_EMAIL")
			Dim user_salt As String = con.ExecQuerySingleResult2(strSQL, Array As String(user_email))
			Dim user_hash As String = Encryption.MD5(old_password & user_salt)
			
			strSQL = Main.DB.Queries.Get("SELECT_USER_DATA_BY_EMAIL_AND_HASH")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email, user_hash))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
				Dim user_name As String = res.GetString("user_name")
				
				Dim salt As String = Encryption.MD5(Rnd(100001, 999999))
				Dim hash As String = Encryption.MD5(new_password & salt)
				Dim code As String = Encryption.SHA1(hash)
				
				strSQL = Main.DB.Queries.Get("UPDATE_USER_DATA_BY_EMAIL_HASH")
				con.ExecNonQuery2(strSQL, Array As String(hash, salt, code, user_email, user_hash))
				
				' Send email
				SendEmail(user_name, user_email, "change", "null", "null")
				Main.DB.WriteUserLog("password/change", "success", "[User Change Password] " & user_email, user_id)
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "Your Password Is Now Updated"
			Else
				HRM.ResponseCode = 404
				HRM.ResponseError = "User Not Found"
			End If
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error JSON Input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub PostForgotPassword As HttpResponseMessage
	#region Documentation
	' #Version = v2
	' #Desc = Forgot password
	' #Elements = ["forgot"]
	' #Body = {<br>&nbsp; "email": "user_email"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_email As String = data.Get("email")

			If user_email = "" Then
				msg_text = "[Please Enter Your Email]"
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Please Enter Your Email"
				Return HRM
			End If

			If Utility.Validate_Email(user_email) = False Then
				msg_text = "[Please Enter A Valid Email]"
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Please Enter A Valid Email"
				Return HRM
			End If

			strSQL = Main.DB.Queries.Get("SELECT_USER_DATA_BY_EMAIL")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
				Dim user_name As String = res.GetString("user_name")
				
				Dim code As String = Encryption.MD5(Rnd(100001, 999999))
				strSQL = Main.DB.Queries.Get("UPDATE_USER_RESET_CODE_BY_EMAIL")
				con.ExecNonQuery2(strSQL, Array As String(code, user_email))
				msg_text = "[User Forgot Password] " & user_email
				
				' Send email
				SendEmail(user_name, user_email, "forgot", code, "null")
				Main.DB.WriteUserLog("password/forgot", "success", msg_text, user_id)

				HRM.ResponseCode = 200
				HRM.ResponseMessage = "Please Check Your Email To Reset Your Password"
			Else
				HRM.ResponseCode = 404
				HRM.ResponseError = "Account Not Found"
			End If
		Else
			HRM.ResponseCode = 400
			HRM.ResponseError = "Error JSON Input"
		End If
	Catch
		LogError(LastException)
		HRM.ResponseCode = 422
		HRM.ResponseError = "Error Execute Query"
	End Try
	Main.DB.CloseDB(con)
	Return HRM
End Sub

Public Sub GetResetPassword (code As String)
	#region Documentation
	' #Hide
	' #Version = v2
	' #Desc = Confirm Reset password by given reset code
	' #Elements = ["reset", ":code"]
	' #DefaultFormat = raw
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Dim format As String = Request.GetParameter("format")
	Try
		'Log(code)
		strSQL = Main.DB.Queries.Get("SELECT_USER_EMAIL_BY_CODE")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(code))
		If res.NextRow Then
			Dim user_id As Int = res.GetInt("user_id")
			Dim user_name As String = res.GetString("user_name")
			Dim user_email As String = res.GetString("user_email")
			
			' You may use other method To generate a more complex password with alphanumeric
			Dim salt As String = Encryption.MD5(Rnd(100001, 999999))
			Dim temp As String = Encryption.MD5(Rnd(100001, 999999))
			temp = temp.SubString(temp.Length - 8) ' get last 8 letters
			Dim hash As String = Encryption.MD5(temp & salt)
			Dim reset_code As String = Encryption.MD5(hash)
			'Dim reset_code As String = Encryption.MD5(Rnd(100001, 999999))
			msg_text = "[User Confirm Reset Password] " & user_email
							
			strSQL = Main.DB.Queries.Get("UPDATE_USER_DATA_BY_EMAIL_AND_CODE")
			con.ExecNonQuery2(strSQL, Array As String(hash, salt, reset_code, user_email, code))
				
			' Send email
			SendEmail(user_name, user_email, "reset", "null", temp)
			Main.DB.WriteUserLog("password/reset", "success", msg_text, user_id)
			
			If format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "User Confirmed Reset Password"
			Else				
				HRT.ResponseBody = $"<h1>Confirm Reset Password</h1>
				<p>Password reset successfully.<br/>
				Please check your email for temporary password.</p>"$
			End If
		Else
			If format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid Reset Code"
			Else
				HRT.ResponseBody = $"<h1>Invalid Reset Code</h1><p>Please contact system admin at ${Main.Config.Get("ADMIN_EMAIL")}</p>"$
			End If
		End If
	Catch
		LogError(LastException.Message)
		If format.EqualsIgnoreCase("json") Then
			HRM.ResponseCode = 422
			HRM.ResponseError = "Error Execute Query"
		Else
			HRT.ResponseBody = $"<h1>Error Execute Query</h1><p>Please report to the developer</p>"$
		End If
	End Try
	Main.DB.CloseDB(con)
	'Return HRM
	If format.EqualsIgnoreCase("json") Then
		Utility.ReturnHttpResponse(HRM, Response)
	Else
		Utility.ReturnHtmlBody(HRT, Response)
	End If
End Sub

Private Sub SendEmail (user_name As String, user_email As String, action As String, reset_code As String, temp_password As String)
	Dim smtp As SMTP
	Try
		Dim APP_TRADEMARK As String = Main.Config.Get("APP_TRADEMARK")
		Dim SMTP_USERNAME As String = Main.Config.Get("SMTP_USERNAME")
		Dim SMTP_PASSWORD As String = Main.Config.Get("SMTP_PASSWORD")
		Dim SMTP_SERVER As String = Main.Config.Get("SMTP_SERVER")
		Dim SMTP_USESSL As String = Main.Config.Get("SMTP_USESSL")
		Dim SMTP_PORT As Int = Main.Config.Get("SMTP_PORT")
		Dim EmailSubject As String
		Dim EmailBody As String
		
		Select action
			Case "change"
				EmailSubject = "Your password has been changed"
				EmailBody = $"Hi ${user_name},<br />
				We have noticed that you have changed your password recently.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, please ignore this email.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$							
			Case "forgot"
				EmailSubject = "Request to reset your password"
				EmailBody = $"Hi ${user_name},<br />
				We have received a request from you to reset your password.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, click the following link to confirm:<br />
				<br />
				<a href="${Main.ROOT_URL}${Main.ROOT_PATH}confirm-reset-password/${reset_code}" id="reset-link" title="reset" target="_blank">${Main.ROOT_URL}${Main.ROOT_PATH}confirm-reset-password/${reset_code}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				If you have changed your mind, just ignore this email.<br />				
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case "reset"
				EmailSubject = "Your password has been reset"
				EmailBody = $"Hi ${user_name},<br />
				Your password has been reset.<br />
				Please use the following temporary password to log in.<br />
				Password: ${temp_password}<br />
				<br />
				Once you are able to log in, please change to a new password.<br />
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case Else
				Log("Wrong parameter")
				'strMain = $"<h1>Send Email</h1>
				'<p>Unrecognized action!</p>"$
				'Utility.ReturnHtml(strMain, Response)
				Return
		End Select
		
		smtp.Initialize(SMTP_SERVER, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, "SMTP")
		If SMTP_USESSL.ToUpperCase = "TRUE" Then smtp.UseSSL = True Else smtp.UseSSL = False
		smtp.Sender = SMTP_USERNAME
		smtp.To.Add(user_email)
		smtp.AuthMethod = smtp.AUTH_LOGIN
		'If HTML_BODY.ToUpperCase = "TRUE" Then smtp.HtmlBody = True Else smtp.HtmlBody = False
		smtp.HtmlBody = True
		smtp.Subject = EmailSubject
		smtp.Body = EmailBody
		LogDebug(smtp.body)
		LogDebug("Sending email...")
		'Dim sm As Object = smtp.Send
		Wait For (smtp.Send) SMTP_MessageSent (Success As Boolean)
		If Success Then
			LogDebug("Message sent successfully")
		Else
			LogDebug("Error sending message")
			LogDebug(LastException)
		End If
	Catch
		LogDebug(LastException)
		Utility.ReturnError("Error Send Email", 400, Response)
	End Try
End Sub