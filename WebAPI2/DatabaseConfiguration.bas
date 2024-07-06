B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Database Configuration class
' Version 2.08
Sub Class_Globals
	Private Conn As Conn
	Private const COLOR_RED 	As Int = -65536     'ignore
	Private const COLOR_GREEN 	As Int = -16711936  'ignore
	Private const COLOR_BLUE 	As Int = -16776961  'ignore
	Private const COLOR_MAGENTA	As Int = -65281     'ignore
End Sub

Public Sub Initialize
	If Not(File.Exists(File.DirApp, "config.ini")) Then
		File.Copy(File.DirAssets, "config.example", File.DirApp, "config.ini")
	End If
	Dim Config As Map = WebApiUtils.ReadMapFile(File.DirApp, "config.ini")
	
	Conn.Initialize
	Conn.DBDir = Config.GetDefault("DbDir", "")
	Conn.DBFile = Config.GetDefault("DbFile", "")
	Conn.DBType = Config.GetDefault("DbType", "")
	Conn.DBHost = Config.GetDefault("DbHost", "")
	Conn.DBPort = Config.GetDefault("DbPort", "")
	Conn.DBName = Config.GetDefault("DbName", "")
	Conn.DriverClass = Config.GetDefault("DriverClass", "")
	Conn.JdbcUrl = Config.GetDefault("JdbcUrl", "")
	Conn.User = Config.GetDefault("User", "")
	Conn.Password = Config.GetDefault("Password", "")
	Conn.MaxPoolSize = Config.GetDefault("MaxPoolSize", 0)
End Sub

' Configure Database (create if not exist)
Public Sub ConfigureDatabase
	Try
		Log("Checking database...")
		#If MySQL
		Dim DBType As String = "MySQL"
		#Else
		Dim DBType As String = "SQLite"
		#End If
		
		If Conn.DBType.EqualsIgnoreCase(DBType) Then
			Main.DBConnector.Initialize(Conn)
			#If MySQL
			Wait For (Main.DBConnector.DBExist2) Complete (DBFound As Boolean)
			#Else
			Dim DBFound As Boolean = Main.DBConnector.DBExist
			#End If
		Else
			ShowBuildConfigurationNotMatch
			Return
		End If
		
		If DBFound Then
			LogColor($"${Conn.DBType} database found!"$, COLOR_BLUE)
		Else
			LogColor($"${Conn.DBType} database not found!"$, COLOR_RED)
			CreateDatabase
		End If
	Catch
		LogError(LastException.Message)
		LogColor("Error checking database!", COLOR_RED)
		Log("Application is terminated.")
		ExitApplication
	End Try
End Sub

Private Sub CreateDatabase
	Log("Creating database...")
	Select Conn.DBType.ToUpperCase
		Case "MYSQL"
			Wait For (Main.DBConnector.DBCreateMySQL) Complete (Success As Boolean)
		Case "SQLITE"
			Wait For (Main.DBConnector.DBCreateSQLite) Complete (Success As Boolean)
	End Select
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If
	
	Log("Creating tables...")
	Dim MDB As MiniORM
	MDB.Initialize(Main.DBOpen, Main.DBEngine)
	MDB.UseTimestamps = True
	MDB.AddAfterCreate = True
	MDB.AddAfterInsert = True
	
	MDB.Table = "tbl_categories"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_name")))
	MDB.Create
	
	MDB.Columns = Array("category_name")
	MDB.Parameters = Array("Hardwares")
	MDB.Insert
	MDB.Parameters = Array("Toys")
	MDB.Insert

	MDB.Table = "tbl_products"
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_id", "Type": MDB.INTEGER)))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_code", "Length": "12")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_name")))
	MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "product_price", "Type": MDB.DECIMAL, "Length": "10,2", "Default": "0.00")))
	MDB.Foreign("category_id", "id", "tbl_categories", "", "")
	MDB.Create
	
	MDB.Columns = Array("category_id", "product_code", "product_name", "product_price")
	MDB.Parameters = Array(2, "T001", "Teddy Bear", 99.9)
	MDB.Insert
	MDB.Parameters = Array(1, "H001", "Hammer", 15.75)
	MDB.Insert
	MDB.Parameters = Array(2, "T002", "Optimus Prime", 1000.00)
	MDB.Insert
	
	Wait For (MDB.ExecuteBatch) Complete (Success As Boolean)
	If Success Then
		LogColor("Database is created successfully!", COLOR_BLUE)
	Else
		LogColor("Database creation failed!", COLOR_RED)
	End If
	MDB.Close
End Sub

Private Sub ShowBuildConfigurationNotMatch
	LogColor($"Build configuration does not match ${Conn.DBType}!"$, COLOR_RED)
	LogColor($"Application is terminated."$, COLOR_RED)
	ExitApplication
End Sub