B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
' Minimal Collections of Map and List class
' Version 0.02
' 2023-06-09 Added code sample when hover Sub Initialize

Sub Class_Globals
	Private mList As List
	Private mMap As Map
	Private mFirst As Map
	Private mLast As Map
End Sub

' Add a new public variable in Sub Process_Globals of Main module
' <code>Public MinimaItem As MinimaList</code>
'
' Initialize inside Sub AppStart before ConfigureServer
' <code>MinimaItem.Initialize</code>
'
' Add the following code inside Sub ConfigureKeyValueStore to read
' <code>
'If MinimaItem.IsInitialized Then
'    MinimaItem.List = KVS.GetDefault("ItemList", MinimaItem.List)
'End If</code>
Public Sub Initialize
	mList.Initialize
	mMap.Initialize
	mFirst.Initialize
	mLast.Initialize
End Sub

Public Sub setList (L1 As List)
	mList = L1
	If mList.Size > 0 Then
		mFirst = mList.Get(0)
		mLast = mList.Get(mList.Size - 1)
	End If
End Sub

Public Sub getList As List
	Return mList
End Sub

Public Sub setMap (M1 As Map)
	mMap = M1
End Sub

Public Sub getMap As Map
	Return mMap
End Sub

' Add new Item
Public Sub Add (M As Map)
	If mList.Size = 0 Then
		M.Put("id", 1)
		mFirst = M
		mLast = M
	Else
		M.Put("id", mList.Get(mList.Size - 1).As(Map).Get("id").As(Long) + 1)
		mLast = M
	End If
	mList.Add(M)
End Sub

' Remove Item by Index
Public Sub Remove (Index As Long)
	If mList.Size > 0 Then
		mList.RemoveAt(Index)
	End If
	If mList.Size = 0 Then
		mFirst.Clear
		mLast.Clear
	Else
		mFirst = mList.Get(0)
		mLast = mList.Get(mList.Size - 1)
	End If
End Sub

' Remove Item by passing a Map object
Public Sub Remove2 (M As Map)
	If mList.Size > 0 Then
		Dim Index As Long
		For Each O As Map In mList
			If O.Get("id") = M.Get("id") Then
				Log("Found")
				mList.RemoveAt(Index)
			End If
			Index = Index + 1
		Next
	End If

	If mList.Size = 0 Then
		mFirst.Clear
		mLast.Clear
	Else
		mFirst = mList.Get(0)
		mLast = mList.Get(mList.Size - 1)
	End If
End Sub

' Remove key in Map by Index
Public Sub RemoveKey (Key As String, Index As Long)
	Dim M As Map = mList.Get(Index)
	If M.ContainsKey(Key) Then
		M.Remove(Key)
	End If
End Sub

' Remove key in Map by passing a Map object
Public Sub RemoveKey2 (Key As String, M As Map)
	'Dim M As Map = mList.Get(Index)
	If M.ContainsKey(Key) Then
		M.Remove(Key)
	End If
End Sub

' Get index of Item by Map object
Public Sub IndexFromMap (M As Map) As Long
	Dim Index As Long
	For Each O As Map In mList
		If O.Get("id") = M.Get("id") Then
			Log("Found")
			Return Index
		End If
		Index = Index + 1
	Next
	Return -1
End Sub

' Get index of Item by id key
Public Sub IndexFromId (id As Long) As Long
	Dim Index As Long
	For Each O As Map In mList
		If id = O.Get("id") Then
			Log("Found")
			Return Index
		End If
		Index = Index + 1
	Next
	Return -1
End Sub

' Get First Item
Public Sub getFirst As Map
	Return mFirst
End Sub

' Get Last Item
Public Sub getLast As Map
	Return mLast
End Sub

' Find Item based on id key
Public Sub Find (id As Long) As Map
	For Each M As Map In mList
		If id = M.Get("id") Then
			Return M
		End If
	Next
	Return CreateMap()
End Sub