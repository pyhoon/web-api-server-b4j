# Web API Server

Version: 3.00

Create Web API Server using B4X project template

### Preview
![Web API Template](https://raw.githubusercontent.com/pyhoon/web-api-server-b4j/main/Preview/Web%20API%20Template.png)

*If you don't want to connect to any SQL database, see [MinimaList API Server](https://github.com/pyhoon/minimalist-api-b4j)*

*For older version **webapi-b4j**, please check https://github.com/pyhoon/webapi-b4j*

---

## Template:
- Web API Server (3.00).b4xtemplate

## Depends on:
- [WebApiUtils.b4xlib](https://github.com/pyhoon/WebApiUtils-B4J)
- [MiniORMUtils.b4xlib](https://github.com/pyhoon/MiniORMUtils-B4X)

## Features:
- ApiHandler and WebHandler are used for routing to Controller classes
- HelpHandler (optional)
- API documentation is generated automatically. You don't need external tools (e.g Postman or Swagger) for testing.
- Access tokens can be embeded into request header in HelpHandler.
- Controller classes are added to a list in Main module to show in the documentation.
- Configuration
    - Web and API paths
    - Versioning
    - Simple JSON Response (Map or List)
    - Session
    - Cookies
    - Welcome message
- Endpoint
    - Endpoint name is based on controller's name by default e.g ProductsController produces /web/api/v2/products
    - Endpoint name can be overridden by using #Name tag e.g /web/api/v2/product
    - Custom version name using #Version tag e.g v2, live, demo, dev, staging
    - Description in documentation is set using #Desc tag (in Web API v1, it was set by #Desc1, #Desc2 or Literals that was very confusing)
    - API endpoint can be hidden using #Hide tag
- Clients
    - Build-in front-end client (web)
    - Compatible with [**Web API Client (1.05).b4xtemplate**](https://github.com/pyhoon/web-api-client-b4x) (B4A, B4i, B4J)

### Code Example
```basic
Private Sub GetCategory (id As Long)
    ' #Version = v2
    ' #Desc = Read one Category by id
    ' #Elements = [":id"]

    DB.Table = "tbl_category"
    DB.Find(id)
    If DB.Found Then
        HRM.ResponseCode = 200
        HRM.ResponseObject = DB.First
    Else
        HRM.ResponseCode = 404
        HRM.ResponseError = "Category not found"
    End If
    DB.Close
    ReturnApiResponse
End Sub
```

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
