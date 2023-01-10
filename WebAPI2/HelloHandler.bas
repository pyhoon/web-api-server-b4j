B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Hello Handler class
' Version 2.00
Sub Class_Globals
	Private Response As ServletResponse
	Private Elements() As String
	Private Literals() As String = Array As String("", "hello") ' Plural, Singular 'ignore
	Private Const SECOND_ELEMENT As Int = Main.Element.Second
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Response = resp
	
	Elements = Regex.Split("/", req.RequestURI)
	If ElementLastIndex = SECOND_ELEMENT Then
		GetShowMessage(Elements(SECOND_ELEMENT))
	Else
		GetShowHelloWorld
	End If
End Sub

Private Sub ElementLastIndex As Int
	Return Elements.Length - 1
End Sub

Public Sub GetShowMessage (slug As String)
	' #Desc = Return slug as message
	' #Elements = ["this-is-a-slug"]
	Utility.ReturnSuccess(CreateMap("message": slug), 200, Response)
End Sub

Public Sub GetShowHelloWorld
	' #Desc = Return hello-world as message
	Utility.ReturnSuccess(CreateMap("message": "Hello World!"), 200, Response)
End Sub