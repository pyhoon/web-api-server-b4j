B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' DatabaseConnector class
' Version 2.04
Sub Class_Globals
	Private Pool As ConnectionPool
	Private DB As SQL
	Private H2 As SQL
	Private Conn As Conn
	Private Conn2 As Conn
	Private DBType As String
	Private DriverClass As String
	Private JdbcUrl As String
	Private DBDir As String
	Private DBFile As String
	Private DBName As String
	Private User As String
	Private Password As String
	Private MaxPoolSize As Int
	Type Conn (DBType As String, DriverClass As String, JdbcUrl As String, User As String, Password As String, MaxPoolSize As Int, DBName As String, DBDir As String, DBFile As String)
End Sub

Public Sub Initialize (mConn As Conn)
	Conn = mConn
	DBType = Conn.DBType
	DriverClass = Conn.DriverClass
	JdbcUrl = Conn.JdbcUrl
	DBDir = Conn.DBDir
	DBFile = Conn.DBFile
	DBName = Conn.DBName
	User = Conn.User
	Password = Conn.Password
	MaxPoolSize = Conn.MaxPoolSize
	
	Select DBType
		Case "MySQL", "SQL Server", "Firebird", "PostgreSQL"
			Pool.Initialize(DriverClass, JdbcUrl, User, Password)
			If MaxPoolSize > 0 Then
				Dim jo As JavaObject = Pool
				jo.RunMethod("setMaxPoolSize", Array(MaxPoolSize))
			End If
		Case "SQLite"
			If DriverClass <> "" And JdbcUrl <> "" Then
				If JdbcUrl.Length > "jdbc:sqlite:".Length Then
					Dim Temp As String = JdbcUrl.SubString("jdbc:sqlite:".Length)
				End If
					
				If Temp = DBFile Then
					DBDir = File.DirApp
				Else
					DBFile = File.GetName(Temp)
					DBDir = Temp.Replace($"/${DBFile}"$, "")
				End If
					
				If File.Exists(DBDir, "") = False Then
					File.MakeDir(DBDir, "")
				End If
				DB.Initialize(DriverClass, JdbcUrl)
			Else
				If DBDir = "" Then DBDir = File.DirApp
				If DBFile = "" Then DBFile = "data.db"
				DB.InitializeSQLite(DBDir, DBFile, True)
			End If
		Case "DBF"
			DB.Initialize(Conn.DriverClass, Conn.JdbcUrl)
			H2.Initialize(Conn2.DriverClass, Conn2.JdbcUrl)
	End Select
End Sub

Public Sub InitializeH2 (mConn As Conn)
	Conn2 = mConn
End Sub

Public Sub DBOpen As SQL
	Select DBType
		Case "MySQL", "SQL Server", "Firebird", "PostgreSQL"
			Return Pool.GetConnection
		Case "SQLite", "DBF"
			Return DB
	End Select
	Return Null
End Sub

Public Sub GetH2 As SQL
	Return H2
End Sub

Public Sub getDBFolder As String
	Return DBDir
End Sub

' Return DBType
Public Sub getDBEngine As String
	Return DBType
End Sub

' Return SQL query for Last Insert ID based on DBType
Public Sub getLastInsertIDQuery As String
	Select DBType
		Case "SQLite"
			Dim qry As String = "SELECT LAST_INSERT_ROWID()"
		Case "MySQL"
			Dim qry As String = "SELECT LAST_INSERT_ID()"
		Case "SQL Server"
			Dim qry As String = "SELECT SCOPE_IDENTITY()"
		Case "Firebird"
			Dim qry As String = "SELECT PK"
		Case "PostgreSQL"
			Dim qry As String = "SELECT LASTVAL()"
		Case Else
			Dim qry As String = "SELECT 0"
	End Select
	Return qry
End Sub

' Not applied for SQLite
Public Sub DBClose
	Select DBType
		Case "SQLite"
			' Do not close SQLite in release mode
		Case Else
			If DB <> Null And DB.IsInitialized Then DB.Close
	End Select
End Sub

' Check database can be connected
Public Sub DBTest As Boolean
	Dim con As SQL = DBOpen
	If con <> Null And con.IsInitialized Then
		con.Close
		Return True
	End If
	Return False
End Sub

' Check Database exists
Public Sub DBExist As ResumableSub
	Try
		Dim DBFound As Boolean			
		If DBType.EqualsIgnoreCase("MySQL") Then
			Dim InformationSchemaJdbcUrl As String = JdbcUrl.Replace(DBName, "information_schema")
			Dim SQL1 As SQL
			SQL1.Initialize2(DriverClass, InformationSchemaJdbcUrl, User, Password)
			If SQL1 <> Null And SQL1.IsInitialized Then
				Dim qry As String = "SELECT * FROM SCHEMATA WHERE SCHEMA_NAME = ?"
				Dim rs As ResultSet = SQL1.ExecQuery2(qry, Array As String(DBName))
				Do While rs.NextRow
					DBFound = True
				Loop
				rs.Close
			End If
			If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
		End If
	Catch
		LogError(LastException.Message)
	End Try
	Return DBFound
End Sub

' Check SQLite database file exists
Public Sub DBExist2 (mConn As Conn) As Boolean
	Dim DBFound As Boolean
	If File.Exists(mConn.DBDir, mConn.DBFile) Then
		DBFound = True
		'Log(mConn.DBDir)
	End If
	Return DBFound
End Sub

' Create SQLite and MySQL database
Public Sub DBCreate As SQL
	Dim SQL1 As SQL
	Try
		Select DBType
			Case "SQLite"
				SQL1 = DB
				SQL1.ExecNonQuery("PRAGMA journal_mode = wal")
			Case "MySQL"
				Dim InformationSchemaJdbcUrl As String = JdbcUrl.Replace(DBName, "information_schema")				
				SQL1.Initialize2(DriverClass, InformationSchemaJdbcUrl, User, Password)
				Dim qry As String = $"CREATE DATABASE ${DBName} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"$
				SQL1.ExecNonQuery(qry)
				Dim qry As String = $"USE ${DBName}"$
				SQL1.ExecNonQuery(qry)
		End Select
	Catch
		Log(LastException.Message)
	End Try
	Return SQL1
End Sub

' Not applied for SQLite
Public Sub Close (SQL1 As SQL)
	Select DBType
		Case "SQLite"
			' Do not close SQLite in release mode
		Case Else
			If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
	End Select
End Sub

Public Sub GetDateTime As String
	Try
		Select DBType
			Case "SQLite"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case "MySQL"
				Dim qry As String = $"SELECT now()"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Return DateTime.Date(DateTime.Now)
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		LogError(LastException.Message)
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	Return str
End Sub

Public Sub GetDate As String
	Try	
		Select DBType
			Case "SQLite"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case "MySQL"
				Dim qry As String = $"SELECT now()"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Return DateTime.Date(DateTime.Now)
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		LogError(LastException.Message)
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	Return str
End Sub