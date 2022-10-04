B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=8.1
@EndOfDesignText@
' Password Handler class
' Version 2.00
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private HRM As HttpResponseMessage
	Private HRT As HttpResponseContent
	Private Elements() As String
	Private Literals() As String = Array As String("", "password", "{action}", "{code}")
End Sub

Public Sub Initialize

End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	
	HRM.Initialize

	Elements = Regex.Split("/", req.RequestURI)
	Dim SupportedMethods As List = Array As String("GET", "POST")
	If Utility.CheckAllowedVerb(SupportedMethods, Request.Method) = False Then
		Utility.ReturnMethodNotAllow(Response)
		Return
	End If
	
	ProcessRequest
End Sub


Private Sub ProcessRequest
	Try
		Select Request.Method.ToUpperCase
			Case "GET"
				Select Elements.Length - 1
					Case Main.Element.Third ' /password/:action/:code
						If Elements(Main.Element.First) = Literals(1) Then
							Select Elements(Main.Element.Second)
								Case "confirm-reset"
									Dim ResetCode As String = Elements(Main.Element.Third)
									'Dim Format As String = Request.GetParameter("format")
									'Utility.ReturnHttpResponse(GetConfirmReset(ResetCode, Format), Response)
									GetConfirmReset(ResetCode)
									Return
							End Select
						End If
				End Select
			Case "POST"
				Select Elements.Length - 1
					Case Main.Element.Second ' /password/:action
						If Elements(Main.Element.First) = Literals(1) Then
							Select Elements(Main.Element.Second)
								Case "change"
									ReturnResponse(PostChangePassword)
									Return
								Case "reset"
									ReturnResponse(PostResetPassword)
									Return
							End Select
						End If
				End Select
		End Select
	Catch
		LogError(LastException.Message)
		'Dim Format As String = Request.GetParameter("format")
		'If Format.EqualsIgnoreCase("json") Then
		'	Utility.ReturnBadRequest(Response)
		'Else
		'	Dim strMessage As String = $"<h1>Bad Request</h1><p>Please refer to documentation</p>"$
		'	Utility.ReturnHTML(strMessage, Response)
		'End If
	End Try
	Dim Format As String = Request.GetParameter("format")
	If Format.EqualsIgnoreCase("json") Then
		Utility.ReturnBadRequest(Response)
	Else
		Dim strMessage As String = $"<h1>Bad Request</h1><p>Please refer to documentation</p>"$
		Utility.ReturnHTML(strMessage, Response)
	End If
End Sub

Private Sub ReturnResponse (Message As HttpResponseMessage)
	If Main.SimpleResponse Then
		Utility.ReturnSimpleHttpResponse(Message, Response)
	Else
		Utility.ReturnHttpResponse(Message, Response)
	End If
End Sub

Private Sub PostChangePassword As HttpResponseMessage
	#region Documentation
	' #Desc = Change password
	' #Elements = ["change"]
	' #Body = {<br>&nbsp; "eml": "user_email",<br>&nbsp; "old": "current_password",<br>&nbsp; "new": "new_password"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_email As String = data.Get("eml")
			Dim old_password As String = data.Get("old")
			Dim new_password As String = data.Get("new")
			If user_email = "" Or old_password = "" Or new_password = "" Then
				msg_text = "[Value Not Set]"
				Main.DB.WriteUserLog("password/change", "fail", msg_text, 0)
				'Utility.ReturnError("Error No Value", 400, Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error No Value"
				Return HRM
			End If
			If old_password = new_password Then
				msg_text = "[Same Password]"
				Main.DB.WriteUserLog("password/change", "fail", msg_text, 0)
				'Utility.ReturnError("Error-Same-Value", Response)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error Same Value"
				Return HRM
			End If
			
			strSQL = Main.Queries.Get("SELECT_USER_SALT_BY_EMAIL")
			Dim user_salt As String = con.ExecQuerySingleResult2(strSQL, Array As String(data.Get("eml")))
			Dim user_hash As String = Utility.MD5(old_password & user_salt)
			
			strSQL = Main.Queries.Get("SELECT_USER_DATA_BY_EMAIL_AND_HASH")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email, user_hash))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
				Dim user_name As String = res.GetString("user_name")
				
				Dim salt As String = Utility.MD5(Rnd(100001, 999999))
				Dim hash As String = Utility.MD5(new_password & salt)
				Dim code As String = Utility.SHA1(hash)
				
				strSQL = Main.Queries.Get("UPDATE_USER_DATA_BY_EMAIL_HASH")
				con.ExecNonQuery2(strSQL, Array As String(hash, salt, code, user_email, user_hash))
				msg_text = "[User Change Password] " & user_email
				
				' Send email
				SendEmail(user_name, user_email, "change", "null", "null")
				Main.DB.WriteUserLog("password/change", "success", msg_text, user_id)
				HRM.ResponseCode = 200
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

Private Sub PostResetPassword As HttpResponseMessage
	#region Documentation
	' #Desc = Reset password
	' #Elements = ["reset"]
	' #Body = {<br>&nbsp; "eml": "user_email"<br>}
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Try
		Dim data As Map = Utility.RequestData(Request)
		If data.IsInitialized Then
			Dim user_email As String = data.Get("eml")

			If user_email = "" Then
				msg_text = "[Value Not Set]"
				Main.DB.WriteUserLog("password/reset", "fail", msg_text, 0)
				Main.DB.CloseDB(con)
				HRM.ResponseCode = 400
				HRM.ResponseError = "Error No Value"
				Return HRM
			End If

			strSQL = Main.Queries.Get("SELECT_USER_DATA_BY_EMAIL")
			Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(user_email))
			If res.NextRow Then
				Dim user_id As Int = res.GetInt("user_id")
				Dim user_name As String = res.GetString("user_name")
				
				Dim code As String = Utility.MD5(Rnd(100001, 999999))
				strSQL = Main.Queries.Get("UPDATE_USER_RESET_CODE_BY_EMAIL")
				con.ExecNonQuery2(strSQL, Array As String(code, user_email))
				msg_text = "[User Reset Password] " & user_email
				
				' Send email
				SendEmail(user_name, user_email, "reset", code, "null")
				Main.DB.WriteUserLog("password/reset", "success", msg_text, user_id)

				HRM.ResponseCode = 200
				HRM.ResponseError = "User Reset Password"
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

Private Sub GetConfirmReset (code As String) 'As HttpResponseMessage
	#region Documentation
	' #Desc = Confirm Reset password by given verification code
	' #Elements = ["confirm-reset", ":code"]
	' #DefaultFormat = raw
	#End region
	Dim con As SQL = Main.DB.GetConnection
	Dim msg_text As String
	Dim strSQL As String
	Dim format As String = Request.GetParameter("format")
	Try
		'Log(code)
		strSQL = Main.Queries.Get("SELECT_USER_EMAIL_BY_CODE")
		Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(code))
		If res.NextRow Then
			Dim user_id As Int = res.GetInt("user_id")
			Dim user_name As String = res.GetString("user_name")
			Dim user_email As String = res.GetString("user_email")
			
			' You may use other method To generate a more complex password with alphanumeric
			Dim salt As String = Utility.MD5(Rnd(100001, 999999))
			Dim temp As String = Utility.MD5(Rnd(100001, 999999))
			temp = temp.SubString(temp.Length - 8) ' get last 8 letters
			Dim hash As String = Utility.MD5(temp & salt)
			Dim reset_code As String = Utility.MD5(hash)
			'Dim reset_code As String = Utility.MD5(Rnd(100001, 999999))
			msg_text = "[User Confirm Reset Password] " & user_email
							
			strSQL = Main.Queries.Get("UPDATE_USER_DATA_BY_EMAIL_AND_CODE")
			con.ExecNonQuery2(strSQL, Array As String(hash, salt, reset_code, user_email, code))
				
			' Send email
			SendEmail(user_name, user_email, "confirmreset", "null", temp)
			Main.DB.WriteUserLog("password/confirmreset", "success", msg_text, user_id)
			
			If format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 200
				HRM.ResponseMessage = "User Confirm Reset Password"
			Else
				HRT.ResponseBody = $"<h1>Reset Password</h1><p>User Confirm Reset Password</p>"$
			End If
		Else
			If format.EqualsIgnoreCase("json") Then
				HRM.ResponseCode = 400
				HRM.ResponseError = "Invalid Reset Code"
			Else
				HRT.ResponseBody = $"<h1>Invalid Reset Code</h1><p>Please refer to documentation</p>"$
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
	Dim strMain As String
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
			Case "reset"
				EmailSubject = "Request to reset your password"
				EmailBody = $"Hi ${user_name},<br />
				We have received a request from you to reset your password.<br />
				<br />
				If this action is not initiated by you, please contact us immediately.<br />
				Otherwise, click the following link to confirm:<br />
				<br />
				<a href="${Main.ROOT_URL}${Main.ROOT_PATH}password/confirmreset/${reset_code}" id="reset-link" title="reset" target="_blank">${Main.ROOT_URL}${Main.ROOT_PATH}password/confirmreset/${reset_code}</a><br />
				<br />
				If the link is not working, please copy the url to your browser.<br />
				If you have changed your mind, just ignore this email.<br />				
				<br />
				Regards,<br />
				<em>${APP_TRADEMARK}</em>"$
			Case "confirmreset"
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
				
				strMain = $"<h1>Confirm Reset Password</h1>
				<p>Password reset successfully.<br/>Please check your email for temporary password.</p>"$
				Utility.ReturnHTML(strMain, Response)
			Case Else
				strMain = $"<h1>Send Email</h1>
				<p>Unrecognized action!</p>"$
				Utility.ReturnHTML(strMain, Response)
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