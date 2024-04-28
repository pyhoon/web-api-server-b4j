﻿B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
' Database Configuration class
' Version 2.07
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

' Configure Database (create if not exist)
Public Sub ConfigureDatabase
	Dim Conn As Conn
	Conn.Initialize
	Conn.DBType = Main.Config.GetDefault("DbType", "")
	Conn.DBName = Main.Config.GetDefault("DbName", "")
	Conn.DBHost = Main.Config.GetDefault("DbHost", "")
	Conn.DBPort = Main.Config.GetDefault("DbPort", "")
	Conn.DBDir = Main.Config.GetDefault("DbDir", "")
	Conn.DriverClass = Main.Config.GetDefault("DriverClass", "")
	Conn.JdbcUrl = Main.Config.GetDefault("JdbcUrl", "")
	Conn.User = Main.Config.GetDefault("User", "")
	Conn.Password = Main.Config.GetDefault("Password", "")
	Conn.MaxPoolSize = Main.Config.GetDefault("MaxPoolSize", 0)
	Try
		'Log("Checking database...")
		Select Conn.DBType.ToUpperCase
			Case "SQLITE"
				#If SQLite
				Dim DBFound As Boolean
				If File.Exists(Conn.DBDir, Conn.DBName) Then
					DBFound = True
				End If
				Main.DBConnector.Initialize(Conn)
				#Else
				LogColor($"Build configuration does not match ${Conn.DBType} database settings!"$, -65536)
				LogColor($"Application is terminated."$, -65536)
				ExitApplication
				Return
				#End If
			Case "MYSQL"
				#If MYSQL
				Main.DBConnector.Initialize(Conn)
				Wait For (Main.DBConnector.DBExist) Complete (DBFound As Boolean)
				#Else
				LogColor($"Build configuration does not match ${Conn.DBType}!"$, -65536)
				LogColor($"Application is terminated."$, -65536)
				ExitApplication
				Return
				#End If
			Case Else
				Main.DBConnector.Initialize(Conn)
				Wait For (Main.DBConnector.DBExist) Complete (DBFound As Boolean)
		End Select
		If DBFound Then
			Log($"${Conn.DBType} database found!"$)
		Else
			LogColor($"${Conn.DBType} database not found!"$, -65536)			
			CreateDatabase
		End If
	Catch
		LogError(LastException.Message)
		LogColor("Error checking database!", -65536)
		Log("Application is terminated.")
		ExitApplication
	End Try
End Sub

Private Sub CreateDatabase
	Log("Creating database...")
	Wait For (Main.DBConnector.DBCreate) Complete (Success As Boolean)
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
		Log("Database is created successfully!")
	Else
		Log("Database creation failed!")
	End If
	MDB.Close
End Sub