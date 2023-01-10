B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.71
@EndOfDesignText@
' Database Object-Relational Mapper (DORM) class
' Version 0.02
Sub Class_Globals
	Private SQL As SQL
	Private strTable As String
	'Private Error As String 'ignore
	Private DateTimeMethods As Map
	Private DBStatement As String
	Private DBLimit As String
	Private Condition As String
	Private DBColumns As List
	Private DBParameters As List
	Private BlnFirst As Boolean
	Private BlnUpdateModifiedDate As Boolean
	Public DBTable As ORMTable
	Public DBResult As ORMDBResult
	Public ResultSet As ResultSet
	'Private DBColumn As Map
	Public Const INTEGER As String = "INTEGER"
	Public Const DECIMAL As String = "NUMERIC" ' "DECIMAL"
	Public Const VARCHAR As String = "TEXT" ' "VARCHAR"
	Type ORMDBResult (Tag As Object, Columns As Map, Rows As List)
	Type ORMTable (ResultSet As ResultSet, Count As Int, Data As List, Row As Map, First As Map)
	Type ORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, DefaultValue As String, Nullable As Boolean, AutoIncrement As Boolean)
	Type ORMFilter (Column As String, Operator As String, Value As String)
End Sub

Public Sub Initialize (mSQL As SQL)
	SQL = mSQL
	DateTimeMethods = CreateMap(91: "getDate", 92: "getTime", 93: "getTimestamp")
	'Parameters.Initialize
End Sub

Public Sub setTable (mTable As String)
	strTable = mTable
	Reset
End Sub

Public Sub getTable As String
	Return strTable
End Sub

'Public Sub DataResult As ORMDBResult
'	Return DBResult
'End Sub

Public Sub setDataColumn (DataColumns As List)
	DBColumns = DataColumns
End Sub

'Public Sub getDataColumn As Map
'	Return DBColumn
'End Sub

Public Sub setUpdateModifiedDate (Value As Boolean)
	BlnUpdateModifiedDate = Value
End Sub

Public Sub Reset
	DBStatement = $"SELECT * FROM ${strTable}"$
	'DBStatement = DBStatement & " WHERE deleted_date IS NULL"
	Condition = ""
	'Condition = " WHERE deleted_date IS NULL"
End Sub

Public Sub First As Map
	BlnFirst = True
	Return DBTable.First
End Sub

Public Sub Find (id As Int) As Map
	'Condition = $" AND id = ${id}"$
	If Condition.Length > 0 Then Condition = " AND " Else Condition = " WHERE "
	Condition = Condition & $"id = ${id}"$
	OrderBy(Null, "")
	Return DBTable.Row
End Sub

' Returns number of rows in the result
Public Sub getCount As Int
	'OrderBy(Null, "")
	Return DBTable.Count
End Sub

Public Sub setSelect (Columns As List)
	Dim AC As Boolean ' Add Comma
	Dim SB As StringBuilder
	SB.Initialize
	For Each Col In Columns
		If AC Then SB.Append(",")
		SB.Append(" " & Col)
		AC = True
	Next
	DBStatement = DBStatement.Replace($"SELECT * FROM"$, "SELECT" & SB.ToString & " FROM")
End Sub

Public Sub Results As List
	Return DBTable.Data
End Sub

'Public Sub ResultSet As ResultSet
'	Return DBTable.ResultSet
'End Sub

Public Sub OrderBy (Col As Map, Limit As String) As ORMDBResult
	If DBStatement.Length = 0 Then Return Null
	If Condition.Length > 0 Then DBStatement = DBStatement & Condition
	If Col.IsInitialized Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each k As String In Col.Keys
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(k & " " & Col.Get(k))
		Next
		DBStatement = DBStatement & $" ORDER BY ${sb.ToString}"$
	End If
	If Limit.Length > 0 Then DBStatement = DBStatement & $" LIMIT ${Limit}"$ ' Limit 10, 10 <-- second parameter is OFFSET
	Try
		Dim RS As ResultSet = SQL.ExecQuery(DBStatement)
		DBTable.Initialize
		DBTable.Data.Initialize
		DBTable.ResultSet = RS
		Dim jrs As JavaObject = RS
		Dim rsmd As JavaObject = jrs.RunMethod("getMetaData", Null)
		Dim cols As Int = RS.ColumnCount
		Dim res As ORMDBResult
		res.Initialize
		res.columns.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
		For i = 0 To cols - 1
			res.columns.Put(RS.GetColumnName(i), i)
		Next
		res.Rows.Initialize
		Do While RS.NextRow ' And limit > 0
			Dim row(cols) As Object
			Dim map1 As Map
			map1.Initialize
			For i = 0 To cols - 1
				Dim ct As Int = rsmd.RunMethod("getColumnType", Array(i + 1))
				'check whether it is a blob field
				If ct = -2 Or ct = 2004 Or ct = -3 Or ct = -4 Then
					row(i) = RS.GetBlob2(i)
				Else if ct = 2 Or ct = 3 Then
					row(i) = RS.GetDouble2(i)
				Else If DateTimeMethods.ContainsKey(ct) Then
					Dim SQLTime As JavaObject = jrs.RunMethodJO(DateTimeMethods.Get(ct), Array(i + 1))
					If SQLTime.IsInitialized Then
						row(i) = SQLTime.RunMethod("getTime", Null)
					Else
						row(i) = Null
					End If
				Else
					row(i) = jrs.RunMethod("getObject", Array(i + 1))
				End If
				map1.Put(RS.GetColumnName(i), row(i))
			Next
			res.Rows.Add(row)
			DBTable.Count = res.Rows.Size
			DBTable.Row = map1
			DBTable.Data.Add(map1)
			If BlnFirst Then
				DBTable.First = map1 ' row
				BlnFirst = False
				Return res
			End If			
		Loop
		RS.Close
	Catch
		Log(LastException)
		'Error = LastException
	End Try
	Return res
End Sub

Public Sub Create (mColumns As List, mTimestamp As Boolean)
	Dim sb As StringBuilder
	sb.Initialize
	' Start construct columns
	For i = 0 To mColumns.Size - 1
		If sb.Length > 0 Then sb.Append(",").Append(CRLF)
		Dim col As ORMColumn = mColumns.Get(i)
		sb.Append(col.ColumnName)
		sb.Append(" ").Append(col.ColumnType)
		If col.ColumnLength.Length > 0 Then sb.Append("(").Append(col.ColumnLength).Append(")")
		If Not(col.Nullable) Then sb.Append(" NOT NULL")
		If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append(col.DefaultValue)
	Next
	' Add Created_Date and Modified_Date columns by default if set to True
	If mTimestamp Then
		sb.Append(",").Append(CRLF)
		sb.Append("created_date INTEGER DEFAULT (strftime('%s000', 'now', 'localtime')),").Append(CRLF) ' SQLite
		sb.Append("modified_date INTEGER,").Append(CRLF)
		sb.Append("deleted_date INTEGER,")
	End If
	Dim cmd As StringBuilder
	cmd.Initialize
	cmd.Append($"CREATE TABLE ${strTable} ("$)
	' id created by mandatory
	cmd.Append($"id INTEGER,"$).Append(CRLF)
	cmd.Append(sb.ToString)
	' Pimary key id created by default
	cmd.Append(CRLF)
	cmd.Append($"PRIMARY KEY(id AUTOINCREMENT)"$)
	cmd.Append(")")
	DBStatement = cmd.ToString
End Sub

' Replace default primary key
Public Sub Primary (mKeys() As String)
	If mKeys.Length < 1 Then Return
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("PRIMARY KEY").Append(" (")
	For i = 0 To mKeys.Length - 1
		If i > 0 Then sb.Append(", ")
		sb.Append(mKeys(i))
	Next
	sb.Append(")")
	DBStatement = DBStatement.Replace("PRIMARY KEY(id AUTOINCREMENT)", sb.ToString)
End Sub

' Insert new foreign keys
Public Sub Foreign (mKey As String, mReferences As String, mOnTable As String, mOnDelete As String, mOnUpdate As String)
	Dim sb As StringBuilder
	sb.Initialize
	' Find last close bracket position and insert new string
	Dim position As Int = DBStatement.LastIndexOf(")")
	sb.Append( DBStatement.SubString2(0, position) )
	'Log ( sb.ToString )
	sb.Append(",")
	sb.Append(CRLF)
	sb.Append( $"FOREIGN KEY (${mKey}) REFERENCES ${mOnTable} (${mReferences})"$ )
	If mOnDelete.Length > 0 Then sb.Append( " ON DELETE " & mOnDelete )
	If mOnUpdate.Length > 0 Then sb.Append( " ON UPDATE " & mOnUpdate )
	sb.Append(")")
	'Log ( sb.ToString )
	DBStatement = sb.ToString
End Sub

Public Sub Execute
	Log ( DBStatement )
	File.WriteString(File.DirApp, "ORM.txt", DBStatement)
	SQL.ExecNonQuery(DBStatement)
End Sub

Public Sub setParameters (Params As List)
	DBParameters = Params
End Sub

Public Sub setLimit (Value As String)
	DBLimit = Value
End Sub

Public Sub Query
	If Condition.Length > 0 Then DBStatement = DBStatement & Condition
	If DBLimit.Length > 0 Then DBStatement = DBStatement & $" LIMIT ${DBLimit}"$ ' Limit 10, 10 <-- second parameter is OFFSET
	'Log ( DBStatement )
	'File.WriteString(File.DirApp, "ORM.txt", DBStatement)
	Try
		Dim RS As ResultSet
		If DBParameters.IsInitialized Then
			If DBParameters.Size > 0 Then
				RS = SQL.ExecQuery2(DBStatement, DBParameters)
			Else
				RS = SQL.ExecQuery(DBStatement)
			End If
		Else
			RS = SQL.ExecQuery(DBStatement)
		End If

		DBTable.Initialize
		DBTable.Data.Initialize
		DBTable.ResultSet = RS
		'ResultSet = RS
		Dim jrs As JavaObject = RS
		Dim rsmd As JavaObject = jrs.RunMethod("getMetaData", Null)
		'Dim cols As Int = RS.ColumnCount
		Dim cols As Int = RS.ColumnCount
		
		Dim res As ORMDBResult
		res.Initialize
		res.Columns.Initialize
		res.Rows.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
		
'		DBResult.Initialize
'		DBResult.Columns.Initialize
'		DBResult.Tag = Null
		
		For i = 0 To cols - 1
			res.Columns.Put(RS.GetColumnName(i), i)
			'DBResult.columns.Put(RS.GetColumnName(i), i)
		Next
		
		BlnFirst = True
		
		'DBResult.Rows.Initialize
		Do While RS.NextRow ' And limit > 0
			Dim row(cols) As Object
			Dim map1 As Map
			map1.Initialize
			For i = 0 To cols - 1
				Dim ct As Int = rsmd.RunMethod("getColumnType", Array(i + 1))
				'check whether it is a blob field
				If ct = -2 Or ct = 2004 Or ct = -3 Or ct = -4 Then
					row(i) = RS.GetBlob2(i)
				Else if ct = 2 Or ct = 3 Then
					row(i) = RS.GetDouble2(i)
				Else If DateTimeMethods.ContainsKey(ct) Then
					Dim SQLTime As JavaObject = jrs.RunMethodJO(DateTimeMethods.Get(ct), Array(i + 1))
					If SQLTime.IsInitialized Then
						row(i) = SQLTime.RunMethod("getTime", Null)
					Else
						row(i) = Null
					End If
				Else
					row(i) = jrs.RunMethod("getObject", Array(i + 1))
				End If
				map1.Put(RS.GetColumnName(i), row(i))
			Next
			res.Rows.Add(row)
			'DBTable.Count = RS.rows
			'DBResult.Rows.Add(row)
			DBTable.Count = res.Rows.Size
			
			DBTable.Row = map1
			DBTable.Data.Add(map1)
			If BlnFirst Then
				DBTable.First = map1 ' row
				BlnFirst = False
			End If
		Loop
		'RS.Close
	Catch
		Log(LastException)
		'Error = LastException
	End Try
	DBResult = res
	Condition = ""
End Sub

Public Sub getScalar As Object
	If Condition.Length > 0 Then DBStatement = DBStatement & Condition
	'Log ( DBStatement )
	'Log ( DBParameters )
	'File.WriteString(File.DirApp, "ORM.txt", $"${DBStatement}${CRLF}${DBParameters}"$)
	If DBParameters.Size > 0 Then		
		Return SQL.ExecQuerySingleResult2(DBStatement, DBParameters)
	Else
		Return SQL.ExecQuerySingleResult(DBStatement)
	End If
End Sub

Public Sub Save
	If Condition.Length > 0 Then
		Dim sb As StringBuilder
		sb.Initialize
		Dim cmd As String = $"UPDATE ${strTable} SET "$
		For Each col As String In DBColumns
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(col & " = ?")
		Next
		cmd = cmd & sb.ToString 
		If BlnUpdateModifiedDate Then
			cmd = cmd & ", modified_date = DateTime('now', 'localtime')"
		End If
		cmd = cmd & Condition
		Condition = ""
	Else
		Dim sb, vb As StringBuilder
		sb.Initialize
		vb.Initialize
		For Each col As String In DBColumns
			If sb.Length > 0 Then
				 sb.Append(", ")
				 vb.Append(", ")
			Else
				sb.Append(" (")
			End If
			sb.Append(col)
			vb.Append( "?" )
		Next
		sb.Append(") ")
		Dim cmd As String = $"INSERT INTO ${strTable}"$ & sb.ToString & " SELECT " & vb.ToString
	End If
	'Log ( cmd )
	'File.WriteString(File.DirApp, "ORM.txt", cmd & CRLF & CRLF & "param=" & prm.As(String))
	If DBParameters.Size > 0 Then
		SQL.ExecNonQuery2(cmd, DBParameters)
	Else
		SQL.ExecNonQuery(cmd)
	End If
End Sub

'Public Sub Where2 (mFilters As List)
'	Dim sb As StringBuilder
'	sb.Initialize
'	For i = 0 To mFilters.Size - 1
'		'If sb.Length > 0 Then
'			sb.Append(" AND ")
'		'Else
'		'	sb.Append(" WHERE ")
'		'End If
'		Dim ft As ORMFilter = mFilters.Get(i)
'		sb.Append($"${ft.Column} ${ft.Operator} ${ft.Value}"$)
'	Next
'	Condition = sb.ToString
'End Sub

Public Sub setWhere (mStatements As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each statement In mStatements
		If sb.Length > 0 Then sb.Append(" AND ") Else sb.Append(" WHERE ")
		sb.Append(statement)
	Next
	Condition = Condition & sb.ToString
End Sub

Public Sub Delete
	Dim cmd As String = $"DELETE FROM ${strTable}"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	SQL.ExecNonQuery(cmd)
	Condition = ""
End Sub

Public Sub Destroy (ids() As Int)
	If ids.Length < 1 Then Return
	Dim cmd As String
	For i = 0 To ids.Length - 1
		cmd = $"DELETE FROM ${strTable} WHERE id = ?"$
		SQL.AddNonQueryToBatch(cmd, Array(ids(i)))
	Next
	Dim SenderFilter As Object = SQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Log("NonQuery: " & Success)
End Sub

Public Sub SoftDelete
	Dim cmd As String = $"UPDATE ${strTable} SET deleted_date = strftime('%s000', 'now', 'localtime')"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	SQL.ExecNonQuery(cmd)
End Sub

'Tests whether the given table exists (extracted from DBUtils)
Public Sub TableExists (TableName As String) As Boolean
	Dim cmd As String = $"SELECT count(name) FROM sqlite_master WHERE type = 'table' AND name = ? COLLATE NOCASE"$
	Dim count As Int = SQL.ExecQuerySingleResult2(cmd, Array As String(TableName))
	Return count > 0
End Sub

Public Sub CreateORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, DefaultValue As String, Nullable As Boolean, AutoIncrement As Boolean) As ORMColumn
	Dim t1 As ORMColumn
	t1.Initialize
	t1.ColumnName = ColumnName
	t1.ColumnType = ColumnType
	t1.ColumnLength = ColumnLength
	t1.DefaultValue = DefaultValue
	t1.Nullable = Nullable
	t1.AutoIncrement = AutoIncrement
	Return t1
End Sub

Public Sub CreateORMFilter (Column As String, Operator As String, Value As String) As ORMFilter
	Dim t1 As ORMFilter
	t1.Initialize
	t1.Column = Column
	t1.Operator = Operator
	t1.Value = Value
	Return t1
End Sub