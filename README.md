# webapi-2-b4j

Version: 2.00

Build REST API Server Using B4X Template

**Depends on following libraries:** 
- ByteConverter
- JavaObject
- jServer
- Json

*For older version, see* **webapi-b4j (v1.15)** https://github.com/pyhoon/webapi-b4j

## Features
- Redesign Architecture
  - The core handlers (ApiHandler) act like BaseController or Routes
  - ApiHandler routes the RequestURI to controllers e.g /web/api/v2/data
  - HelpHandler (optional) generates API documentation for easy debugging without external tools or clients which embed tokens in request header. HelpHandler is now scanning through controllers class for APIs to list in the documentation instead of reading handlers from b4j project main module in version 1.x
  - Web and API paths can be changed in config.ini
  - Versioning can be enabled or disabled
  - Simple JSON response (Map or List)
  - Session can be toggled
  - Cookies can be toggled
  - Welcome message can be toggled
  - One stop ConfigServer sub to control all the settings
  - Default endpoint name is based on controller's name (e.g /web/api/v2/data for DataController)
  - Overide endpoint name using #Plural (e.g /web/api/v2/data)
  - Custom version name using #Version (e.g v2, live, demo, dev, staging)
  - Description is set using #Desc (i.e no more using #Desc1, #Desc2 or Literals that was very confusing in version 1.x)
  - API endpoint can be hidden using #Hide
  - INTRODUCING: **MinimaList** -> store as Map/List. API server can run without database (or optionally persist as KeyValueStore).

### Code Example
```basic
Public Sub GetOneData (Index As Long)
    ' #Version = v2
    ' #Desc = Read one Item in MinimaList
    ' #Elements = [":index"]
    If Index > Main.Minima.List.Size - 1 Then
        HRM.ResponseCode = 404
        HRM.ResponseError = "Invalid Index Value"
    Else
        Dim M1 As Map = Main.Minima.List.Get(Index)
        HRM.ResponseCode = 200
        HRM.ResponseObject = M1
    End If
  
    If Main.SimpleResponse Then
        Utility.ReturnSimpleHttpResponse(HRM, "Map", Response)
    Else
        Utility.ReturnHttpResponse(HRM, Response)
    End If
End Sub
```

### Preview
![Image01](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-01.png)
![Image02](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-02.png)
![Image03](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-03.png)
![Image04](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-04.png)
![Image05](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-05.png)
![Image06](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-06.png)
![Image07](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-07.png)
![Image08](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-08.png)
![Image09](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-09.png)
![Image10](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-10.png)
![Image11](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/webapi-11.png)

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
