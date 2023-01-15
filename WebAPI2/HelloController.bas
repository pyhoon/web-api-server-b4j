B4J=true
Group=Controllers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Hello Controller class
' Version 2.00
Sub Class_Globals
	'Private Request As ServletRequest
	Private Response As ServletResponse
End Sub

Public Sub Initialize (resp As ServletResponse)
	Response = resp
End Sub

Public Sub GetShowHelloWorldV1
	' #Hide
	' #Version = dev
	' #Desc = Return "Hello World!" as message
	Utility.ReturnSuccess(CreateMap("message": "Hello World!"), 200, Response)
End Sub

Public Sub GetShowMessageV1 (slug As String)
	' #Hide
	' #Version = v1
	' #Desc = Return slug as message
	' #Elements = ["this-is-a-slug"]
	Utility.ReturnSuccess(CreateMap("message": slug), 200, Response)
End Sub

Public Sub GetShowHelloWorld
	' #Version = live
	' #Desc = Return "Hello World!" as message and "2" as version
	Utility.ReturnSuccess(CreateMap("message": "Hello World!", "version": "2"), 200, Response)
End Sub

Public Sub GetShowMessage (slug As String)
	' #Version = v2
	' #Desc = Return slug as message and "2" as version
	' #Elements = ["this-is-a-slug"]
	Utility.ReturnSuccess(CreateMap("message": slug, "version": "2"), 200, Response)
End Sub