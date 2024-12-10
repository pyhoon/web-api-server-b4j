# Web API Server

Version: 3.10

Create Web API Server using B4X project template

### Preview
![Web API Server](https://github.com/pyhoon/web-api-server-b4j/blob/399700b61038dffd3e88b39d5c468dfc4d13249f/web-api-server-b4j.png)

*If you don't want to connect to any SQL database, see [MinimaList API Server](https://github.com/pyhoon/minimalist-api-b4j)*

*For older version **webapi-b4j**, please check https://github.com/pyhoon/webapi-b4j*

---

## Template:
- Web API Server (3.10).b4xtemplate

## Depends on:
- [WebApiUtils.b4xlib](https://github.com/pyhoon/WebApiUtils-B4J)
- [MiniORMUtils.b4xlib](https://github.com/pyhoon/MiniORMUtils-B4X)
- sqlite-jdbc-3.39.3.0.jar (or your preferred version)
- mysql-connector-java-8.0.30.jar (or your preferred version)

## Features:
- Code simplified
- Back to basics - use multiple Server Handlers
- Improved API documentation
- Built-in web front-end (bootstrap 4)

### Code Example
```basic
Private Sub GetCategoryById (Id As Int)
	' #Desc = Read one Category by id
	' #Elements = [":id"]
	DB.Table = "tbl_categories"
	DB.Find(Id)
	If DB.Found Then
		HRM.ResponseCode = 200
		HRM.ResponseObject = DB.First
	Else
		HRM.ResponseCode = 404
		HRM.ResponseError = "Category not found"
	End If
	ReturnApiResponse
	DB.Close
End Sub
```

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
