# webapi-2-b4j

Version: 2.00 beta 3

Build REST API Server Using B4X Template

**Depends on following libraries:** 
- ByteConverter
- Encryption (external library)
- JavaObject
- jNet
- jRandomAccessFile
- jServer
- Json
- jSQL
- jStringUtils

*For older version, see* **webapi-b4j (v1.15)** https://github.com/pyhoon/webapi-b4j

## Features
- Security is main focus in this version
  - JSON Web Tokens (JWT) Authentication (provides access and refresh tokens)
  - Basic Authentication (username-password pair)
  - Token Authentication (testing)
  - Cross-site request forgery (CSRF) protection
  - Cross-Origin Resource Sharing (CORS) filter
  - Secure Sockets Layer (SSL) providing HTTPS redirection
  - Authentication can be achieved using server filters to protect entire api family or ValidateToken sub for single API endpoint
  - Hashing methods e.g MD5, SHA1, SHA256, HMACSHA256
- Redesign Architecture
  - The core handlers (ApiHandler andWeb Handler) act like BaseController or Routes
  - ApiHandler routes the RequestURI to controllers e.g /web/api/v2/posts
  - WebHandler routes the RequestURI for front-end page e.g /web/login
  - HelpHandler generates API documentation for easy debugging without external tools or clients which embed tokens in request header
  - HelpHandler is now scanning through controllers class for API to list in the documentation instead of reading handlers from b4j project main module in version 1.x
  - Web and API paths can be changed in config.ini
  - Versioning can be enabled or disabled
  - Simple JSON response as object (Map) or list
  - Session can be toggled
  - Cookies can be toggled
  - Welcome message can be toggled
  - One stop ConfigServer sub to control all the settings
  - MiniORM, an Object Relational Mapper to generate database queries without writing SQL commands
  - Queries map is still supported for **SQLite** and **MySQL** database queries
  - Default endpoint name is based on controller's name e.g /web/api/v2/post for PostController
  - Overide endpoint name using #Plural e.g /web/api/v2/posts
  - Custom version name e.g v2, live, demo, dev, staging using #Version
  - Description is set using #Desc, no more using #Desc1, #Desc2 or Literals that was very confusing in version 1.x
  - Use a Model map to pass data to html template e.g passing user's name variable to Dashboard in AccountController
  - API endpoint can be hidden using #Hide
- Build-in Web Client
  - New blog front-end (using Bootstrap card layout)
  - Based on Bootstrap, jQuery, FontAwesome icons and Responsive layout suitable for different devices screen size
  - User account registration, activation through email link, forgot password, change password, login, logout
  - Integration with AdminLTE3 dashboard template (simplified)
  - SMTP email server

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
