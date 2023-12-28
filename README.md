# webapi-2-b4j

Version: 2.04

Build Web API Server Using B4X Template

---

**Depends on following libraries:** 
- [WebApiUtils.b4xlib](https://www.b4x.com/android/forum/attachments/webapiutils-b4xlib.148485/)
- [MiniORMUtils.b4xlib](https://www.b4x.com/android/forum/attachments/miniormutils-b4xlib.148489/)

*For older version **webapi-b4j**, please check https://github.com/pyhoon/webapi-b4j*

## Features
- The core handler - ApiHandler, acts like BaseController or Routes class
- ApiHandler routes the RequestURI to controllers e.g /web/api/v2/data
- HelpHandler (optional) generates API documentation for easy debugging without external tools or clients which embed tokens in request header. HelpHandler is now scanning through controllers class for APIs to list in the documentation instead of reading handlers from b4j project main module in version 1.x
- Web and API paths can be changed in config.ini
- Versioning can be enabled or disabled
- Simple JSON response (Map or List)
- Session can be toggled
- Cookies can be toggled
- Welcome message can be toggled
- One stop ConfigServer sub to control all the settings
- Default endpoint name is based on controller's name (e.g /web/api/v2/item for ItemController)
- Overide endpoint name using #Plural (e.g /web/api/v2/items)
- Custom version name using #Version (e.g v2, live, demo, dev, staging)
- Description is set using #Desc (i.e no more using #Desc1, #Desc2 or Literals that was very confusing in version 1.x)
- API endpoint can be hidden using #Hide
- INTRODUCING: **MinimaList** -> store as Map/List. API server can run without database (or optionally persist as KeyValueStore).

### Code Example
```basic
Private Sub GetCategory (id As Long)
    ' #Plural = Categories
    ' #Version = v2
    ' #Desc = Get a Category by id
    ' #Elements = [":id"]
 
    Dim M1 As Map = Main.CategoryList.Find(id)
    If M1.Size > 0 Then
        HRM.ResponseCode = 200
    Else
        HRM.ResponseCode = 404
    End If
    HRM.ResponseObject = M1
    ReturnApiResponse
End Sub
```

### Preview
![Web API Template](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/Web%20API%20Template.png)

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
