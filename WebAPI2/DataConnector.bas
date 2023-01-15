B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' DataConnector class
' Version 2.00
Sub Class_Globals
	Public SQL As SQL
	Public Conn As Conn
	Public Queries As Map
	Public Busy As Boolean
	Private Pool As ConnectionPool
	Type Conn (DbName As String, DbType As String, DriverClass As String, JdbcUrl As String, User As String, Password As String, MaxPoolSize As Int)
End Sub

Public Sub Initialize (Config As Map)
	Conn.Initialize
	Conn.DbName = Config.Get("DbName")
	Conn.DbType = Config.Get("DbType")
	Conn.DriverClass = Config.Get("DriverClass")
	Conn.JdbcUrl = Config.Get("JdbcUrl")
	
	If Conn.DbType.EqualsIgnoreCase("mysql") Then
		Conn.User = Config.Get("User")
		Conn.Password = Config.Get("Password")
		If Config.Get("MaxPoolSize") <> Null Then Conn.MaxPoolSize = Config.Get("MaxPoolSize")
	End If
	
	CheckDatabase
End Sub

Private Sub OpenConnection
	If Conn.DbType.EqualsIgnoreCase("sqlite") Then
		SQL.InitializeSQLite(File.DirApp, Conn.DbName, False)
	End If
	If Conn.DbType.EqualsIgnoreCase("mysql") Then
		Pool.Initialize(Conn.DriverClass, Conn.JdbcUrl, Conn.User, Conn.Password)
		If Conn.MaxPoolSize > 0 Then
			Dim jo As JavaObject = Pool
			jo.RunMethod("setMaxPoolSize", Array(Conn.MaxPoolSize))
		End If
	End If
End Sub

Public Sub GetConnection As SQL
	Try
		If Conn.DbType.EqualsIgnoreCase("mysql") Then
			Return Pool.GetConnection
		End If
		If Conn.DbType.EqualsIgnoreCase("sqlite") Then
			OpenConnection
			Return SQL
		End If
	Catch
		Log(LastException)
	End Try
	Return Null
End Sub

Public Sub CloseDB (con As SQL)
	If con <> Null And con.IsInitialized Then con.Close
	'If Conn.DbType.EqualsIgnoreCase("mysql") Then
	'	If Pool.IsInitialized Then Pool.ClosePool
	'End If
End Sub

Private Sub ConAddSQLQuery (Comm As SQL, Key As String)
	Dim strSQL As String = Queries.Get(Key)
	If strSQL <> "" Then Comm.AddNonQueryToBatch(strSQL, Null)
End Sub

Private Sub ConAddSQLQuery2 (Comm As SQL, Key As String, Val1 As String, Val2 As String)
	Dim strSQL As String = Queries.Get(Key).As(String).Replace(Val1, Val2)
	If strSQL <> "" Then Comm.AddNonQueryToBatch(strSQL, Null)
End Sub

Public Sub CheckConnection As Boolean
	Dim Check As SQL = GetConnection
	If Check <> Null And Check.IsInitialized Then
		Check.Close
		Return True
	End If
	Return False
End Sub

Private Sub CheckDatabase As ResumableSub
	Try
		Dim con As SQL
		Dim DBFound As Boolean
		Dim JdbcUrl As String
		LogColor($"Checking database..."$, -65536)
		
		If Conn.DbType.EqualsIgnoreCase("sqlite") Then
			' Load Database queries
			Queries = Utility.ReadMapFile(File.DirApp, "queries-blog-sqlite.ini")
			If File.Exists(File.DirApp, Conn.DBName) Then
				DBFound = True
			End If
		End If
		
		If Conn.DbType.EqualsIgnoreCase("mysql") Then
			' Load Database queries
			Queries = Utility.ReadMapFile(File.DirApp, "queries-blog-mysql.ini")
			JdbcUrl = Conn.JdbcUrl
			Conn.JdbcUrl = JdbcUrl.Replace(Conn.DBName, "information_schema")
			OpenConnection
			con = GetConnection
			If con.IsInitialized Then
				Dim strSQL As String = Queries.Get("CHECK_DATABASE")
				Dim res As ResultSet = con.ExecQuery2(strSQL, Array As String(Conn.DBName))
				Do While res.NextRow
					DBFound = True
				Loop
				res.Close
			End If
		End If
		If DBFound Then
			Log("Database found!")
		Else   ' Create database if not exist
			Log("Database not found!")
			Log("Creating database...")
			Busy = True ' Prevent JWT reading Client Id and Secret
			If Conn.DbType.EqualsIgnoreCase("sqlite") Then
				con.InitializeSQLite(File.DirApp, Conn.DBName, True)
				con.ExecNonQuery("PRAGMA journal_mode = wal")
			End If
			If Conn.DbType.EqualsIgnoreCase("mysql") Then
				ConAddSQLQuery2(con, "CREATE_DATABASE", "{DBNAME}", Conn.DBName)
				ConAddSQLQuery2(con, "USE_DATABASE", "{DBNAME}", Conn.DBName)
			End If
		
			ConAddSQLQuery(con, "CREATE_TABLE_TBL_CATEGORY")
			ConAddSQLQuery(con, "INSERT_DUMMY_TBL_CATEGORY")
			ConAddSQLQuery(con, "CREATE_TABLE_TBL_POSTS")
			ConAddSQLQuery(con, "INSERT_DUMMY_TBL_POSTS")
			ConAddSQLQuery(con, "CREATE_TABLE_TBL_USERS")
			ConAddSQLQuery(con, "CREATE_TABLE_TBL_USERS_LOG")
			ConAddSQLQuery(con, "CREATE_TABLE_TBL_ERROR")
			ConAddSQLQuery(con, "CREATE_TABLE_CLIENTMASTER")
			ConAddSQLQuery(con, "INSERT_DUMMY_CLIENTMASTER")
			ConAddSQLQuery(con, "CREATE_TABLE_TOKENSECRET")
			ConAddSQLQuery(con, "INSERT_NEW_TOKENSECRET")
			ConAddSQLQuery(con, "CREATE_TABLE_REFRESHTOKEN")
			
			Dim CreateDB As Object = con.ExecNonQueryBatch("SQL")
			Wait For (CreateDB) SQL_NonQueryComplete (Success As Boolean)
			If Success Then
				Log("Database is created successfully!")
			Else
				Log("Database creation failed!")
			End If
		End If
		CloseDB(con)
		If Conn.DbType.EqualsIgnoreCase("mysql") Then
			Conn.JdbcUrl = JdbcUrl	' Revert jdbcUrl to normal
			OpenConnection
		End If
		
		' Debugging
		'con.InitializeSQLite(File.DirApp, Conn.DBName, False)
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TBL_CATEGORY"))
		'con.ExecNonQuery(Queries.Get("INSERT_DUMMY_TBL_CATEGORY"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TBL_POSTS"))
		'con.ExecNonQuery(Queries.Get("INSERT_DUMMY_TBL_POSTS"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TBL_USERS"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TBL_USERS_LOG"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TBL_ERROR"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_CLIENTMASTER"))
		'con.ExecNonQuery(Queries.Get("INSERT_DUMMY_CLIENTMASTER"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_TOKENSECRET"))
		'con.ExecNonQuery(Queries.Get("INSERT_NEW_TOKENSECRET"))
		'con.ExecNonQuery(Queries.Get("CREATE_TABLE_REFRESHTOKEN"))
		'CloseDB(con)
		Return True
	Catch
		LogError(LastException.Message)
		CloseDB(con)
		Log("Error checking database!")
		Log("Application is terminated.")
		ExitApplication
	End Try
	Return False
End Sub

Public Sub ReturnDateTime (TIMEZONE As Int) As String
	Dim str As String
	Dim con As SQL = GetConnection
	Try
		If Conn.DbType.EqualsIgnoreCase("mysql") Then
			Dim strSQL As String = $"SELECT DATE_ADD(now(), INTERVAL ${TIMEZONE} HOUR)"$
		Else If Conn.DbType.EqualsIgnoreCase("sqlite") Then
			Dim Offset As String = IIf(TIMEZONE >= 0, $"+${TIMEZONE}"$, $"-${TIMEZONE}"$)
			Dim strSQL As String = $"SELECT datetime(datetime('now'), '${Offset} hour')"$
		Else
			DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
			Return DateTime.Date(DateTime.Now)
		End If
		str = con.ExecQuerySingleResult(strSQL)
	Catch
		LogError(LastException)
	End Try
	CloseDB(con)
	Return str & $" (UTC${IIf (TIMEZONE > -1, "+", "")}${TIMEZONE})"$
End Sub

Public Sub WriteErrorLog (Module As String, Message As String)
	Dim con As SQL = GetConnection
	Try
		Dim strSQL As String = $"INSERT INTO tbl_error (error_text) SELECT ?"$
		con.ExecNonQuery2(strSQL, Array As String("[" & Module & "]" & Message))
	Catch
		LogDebug("[WriteErrorLog] " & LastException)
	End Try
	CloseDB(con)
End Sub

Public Sub WriteUserLog (log_view As String, log_type As String, log_text As String, log_User As String)
	Dim con As SQL = GetConnection
	Try
		Dim strSQL As String = $"INSERT INTO tbl_users_log
		(log_view,
		log_type,
		log_text,
		log_user)
		SELECT ?, ?, ?, ?"$
		con.ExecNonQuery2(strSQL, Array As String(log_view, log_type, log_text, log_User))
	Catch
		Dim msg_text As String = "[Exception] " & LastException
		WriteErrorLog("WriteUserLog", msg_text)
		'Utility.ReturnError("Error Execute Query", 422, Response)
	End Try
	CloseDB(con)
End Sub