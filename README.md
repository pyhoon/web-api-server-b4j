# webapi-2-b4j

Version: 2.02

Build REST API Server Using B4X Template  
This is a very minimum template where you don't even need to connect to a database to work.  
Optionally you can start with keyValueStore to persist the model. This will be a foundation to more complex Web API projects.

**Depends on following libraries:** 
- ByteConverter
- jServer
- Json
- JavaObject
- KeyValueStore

*For older version **webapi-b4j (v1.15)**, please check https://github.com/pyhoon/webapi-b4j*

## Features
- Redesign Architecture
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
    Dim M1 As Map = Main.Minima.List.Get(Index)
    HRM.ResponseCode = 200
    HRM.ResponseObject = M1
    Utility.ReturnSimpleHttpResponse(HRM, "Map", Response)
End Sub
```

### Preview
![Web API Template](https://raw.githubusercontent.com/pyhoon/webapi-2-b4j/main/Preview/Web%20API%20Template.png)

**Support this project**

<a href="https://paypal.me/aeric80/"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" width="174" title="Buy me a coffee" /></a>
