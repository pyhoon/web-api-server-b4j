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
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Response = resp
	
	Elements = Regex.Split("/", req.RequestURI)
	If Elements.Length - 1 = Main.Element.Second Then
		GetShowMessage(Elements(Main.Element.Second))
	Else
		GetShowHelloWorld
	End If
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