B4J=true
Group=Modules
ModulesStructureVersion=1
Type=StaticCode
Version=9.8
@EndOfDesignText@
' Encryption Code module
' Version 2.00
' Additional Libraries: Encryption
Sub Process_Globals
	
End Sub

Public Sub MD5 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "MD5")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub SHA1 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "SHA-1")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub SHA256 (str As String) As String
	Dim data() As Byte
	Dim MD As MessageDigest
	Dim BC As ByteConverter

	data = BC.StringToBytes(str, "UTF8")
	data = MD.GetMessageDigest(data, "SHA-256")
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub HMACSHA256 (str As String, key As String) As String
	Dim data() As Byte
	Dim MC As Mac
	Dim KG As KeyGenerator
	Dim BC As ByteConverter
	
	KG.Initialize("HMACSHA256")
	KG.KeyFromBytes(key.GetBytes("UTF8"))
	
	MC.Initialise("HMACSHA256", KG.Key)
	MC.Update(str.GetBytes("UTF8"))
	
	data = MC.Sign
	Return BC.HexFromBytes(data).ToLowerCase
End Sub

Public Sub RandomHash As String
	RndSeed(DateTime.Now)
	Dim gen As String = Rnd(1000, 9999)
	gen = gen & Rnd(10000, 99999)
	Return MD5( gen )
End Sub

Public Sub RandomHash2 As String
	RndSeed(DateTime.Now)
	Dim gen As String = Rnd(1000, 9999)
	gen = gen & Rnd(10000, 99999)
	Return SHA256( gen )
End Sub