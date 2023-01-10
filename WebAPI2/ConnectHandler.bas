B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Connect Handler class
' Version 2.00
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Utility.ReturnSimpleConnect("List", resp)
End Sub