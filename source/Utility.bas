B4J=true
Group=App
ModulesStructureVersion=1
Type=StaticCode
Version=10
@EndOfDesignText@
'Utility code module
'Version 3.40
Sub Process_Globals
	
End Sub

Private Sub ReturnAlertScript (SimpleResponseEnable As Boolean, AlertMessage As String, SuccessCode As Int) As String
	If SimpleResponseEnable Then
		Return $"alert("${AlertMessage}")
          location.reload()"$
	Else
		Return $"if (response.a == ${SuccessCode}) {
            alert("${AlertMessage}")
            location.reload()
          }
          else {
            alert(response.a + " " + response.e)
          }"$
	End If
End Sub

' align for update category and add product
Private Sub ReturnAlertScript2 (SimpleResponseEnable As Boolean, AlertMessage As String, SuccessCode As Int) As String
	If SimpleResponseEnable Then
		Return $"    alert("${AlertMessage}")
          location.reload()"$
	Else
		Return $"	  if (response.a == ${SuccessCode}) {
            alert("${AlertMessage}")
            location.reload()
          }
          else {
            alert(response.a + " " + response.e)
          }"$
	End If
End Sub

' align for delete category
Private Sub ReturnAlertScript3 (SimpleResponseEnable As Boolean, AlertMessage As String, SuccessCode As Int) As String
	If SimpleResponseEnable Then
		Return $"	alert("${AlertMessage}")
      location.reload()"$
	Else
		Return $"	if (response.a == ${SuccessCode}) {
        alert("${AlertMessage}")
        location.reload()
      }
      else {
        alert(response.a + " " + response.e)
      }"$
	End If
End Sub

Private Sub ReturnSuccessScript (SimpleResponseEnable As Boolean, ExpectAccessToken As Boolean) As String
	If SimpleResponseEnable Then
		Return $"success: function (data, textStatus, xhr) {
					var content = JSON.stringify(data, undefined, 2)
					$("#alert" + id).fadeOut("fast", function () {
						$("#response" + id).val(content)
						$("#alert" + id).html(xhr.status + " " + textStatus)
						$("#alert" + id).removeClass("alert-danger")
						$("#alert" + id).addClass("alert-success")
						$("#alert" + id).fadeIn()
					})${IIf(ExpectAccessToken, $"
					// Json Web Token specific
					if (content) {
						if ("access_token" in data) {
							localStorage.setItem("access_token", data["access_token"])
							console.log("access token stored!")
						}
					}"$, "")}
				},"$
	Else
		Return $"success: function (data) {
					if (data.s == "ok" || data.s == "success") {
						var content = JSON.stringify(data.r, undefined, 2)
						$("#alert" + id).fadeOut("fast", function () {
							$("#response" + id).val(content)
							$("#alert" + id).html(data.a + " " + data.m)
							$("#alert" + id).removeClass("alert-danger")
							$("#alert" + id).addClass("alert-success")
							$("#alert" + id).fadeIn()
						})${IIf(ExpectAccessToken, $"
						// Json Web Token specific
						if (data.r.length > 0) {
							if ("access_token" in data.r[0]) {
								localStorage.setItem("access_token", data.r[0]["access_token"])
								console.log("access token stored!")
							}
						}"$, "")}
					}
					else {
						var content = JSON.stringify(data.r, undefined, 2)
						$("#alert" + id).fadeOut("fast", function () {
							$("#response" + id).val(content)
							$("#alert" + id).html(data.a + " " + data.e)
							$("#alert" + id).removeClass("alert-success")
							$("#alert" + id).addClass("alert-danger")
							$("#alert" + id).fadeIn()
						})
					}
				},"$
	End If
End Sub

Private Sub ReturnSuccessTableScript (SimpleResponseEnable As Boolean, jsonResponse As String) As String
	If SimpleResponseEnable Then
		Return $"    success: function (response) {
      //console.log(response)
      var tbl_head = ""
      var tbl_body = ""
      if (${jsonResponse}.length) {
        tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>"
        tbl_body += "<tbody>"
        $.each(${jsonResponse}, function () {
          var col_id = ""
          var col_code = ""
          var col_category = ""
          var col_name = ""
          var col_price = ""
          var col_edit = ""
          var id
          var code
          var name
          var price
          var catid
          $.each(this, function (key, value) {
            if (key == "id") {
              col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
              id = value
            }
            else if (key == "product_code") {
              col_code = "<td class=\"align-middle\">" + value + "</td>"
              code = value
            }
            else if (key == "category_name") {
              col_category = "<td class=\"align-middle\">" + value + "</td>"
            }
            else if (key == "product_name") {
              col_name = "<td class=\"align-middle\">" + value + "</td>"
              name = value
            }
            else if (key == "product_price") {
              col_price = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
              price = value
            }
            else if (key == "category_id") {
              catid = value
            }
          })
          col_edit = "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>"
          tbl_body += "<tr>" + col_id + col_code + col_category + col_name + col_price + col_edit + "</tr>"
        })
        tbl_body += "</tbody>"
      }
      else {
        tbl_body = "<tr><td>No results</td></tr>"
      }
      $("#results table").html(tbl_head + tbl_body)
    },"$
	Else
		Return $"    success: function (response) {
      if (response.s == "ok") {
        var tbl_head = ""
        var tbl_body = ""
        if (${jsonResponse}.length) {
          tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>"
          tbl_body += "<tbody>"
          $.each(${jsonResponse}, function () {
            var col_id = ""
            var col_code = ""
            var col_category = ""
            var col_name = ""
            var col_price = ""
            var col_edit = ""
            var id
            var code
            var name
            var price
            var catid
            $.each(this, function (key, value) {
              if (key == "id") {
                col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
                id = value
              }
              else if (key == "product_code") {
                col_code = "<td class=\"align-middle\">" + value + "</td>"
                code = value
              }
              else if (key == "category_name") {
                col_category = "<td class=\"align-middle\">" + value + "</td>"
              }
              else if (key == "product_name") {
                col_name = "<td class=\"align-middle\">" + value + "</td>"
                name = value
              }
              else if (key == "product_price") {
                col_price = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
                price = value
              }
              else if (key == "category_id") {
                catid = value
              }
            })
            col_edit = "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\"  data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>"
            tbl_body += "<tr>" + col_id + col_code + col_category + col_name + col_price + col_edit + "</tr>"
          })
          tbl_body += "</tbody>"
        }
        else {
          tbl_body = "<tr><td>No results</td></tr>"
        }
        $("#results table").html(tbl_head + tbl_body)
      }
      else {
        $(".alert").html(response.e)
        $(".alert").fadeIn()
      }
    },"$
	End If
End Sub

Public Sub GenerateJSFileForCategory (DirName As String, FileName As String, SimpleResponse As SimpleResponse)
	Dim jsonResponse As String = "response.r"
	If SimpleResponse.Enable Then
		If SimpleResponse.Format = "Map" Then
			jsonResponse = "response." & SimpleResponse.DataKey
		Else
			jsonResponse = "response"
		End If
	End If
	Dim script1 As String = $"  $.getJSON("/${Main.conf.ApiName}/categories", function (response) {
    var tbl_head = ""
    var tbl_body = ""
    if (${jsonResponse}.length) {
      tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Name</th><th style=\"width: 90px\">Actions</th></thead>"
      tbl_body += "<tbody>"
      $.each(${jsonResponse}, function () {
        var tbl_row = ""
        var col_id = ""
        var col_name = ""
        var id
        var name
        $.each(this, function (key, value) {
          if (key == "id") {
            col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
            id = value
          }
          else if (key == "category_name") {
            col_name = "<td class=\"align-middle\">" + value + "</td>"
            name = value
          }
        })
        tbl_row = col_id + col_name + "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-name=\"" + name + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>"
        tbl_body += "<tr>" + tbl_row + "</tr>"
      })
      tbl_body += "</tbody>"
    }
    else {
      tbl_body = "<tr><td>No results</td></tr>"
    }
    $("#results table").html(tbl_head + tbl_body)
  })"$
	Dim script2 As String = $"$(document).on("click", ".edit", function (e) {
  var id = $(this).attr("data-id")
  var name = $(this).attr("data-name")
  $("#id1").val(id)
  $("#name1").val(name)
})"$
	Dim script3 As String = $"$(document).on("click", ".delete", function (e) {
  var id = $(this).attr("data-id")
  var name = $(this).attr("data-name")
  $("#id2").val(id)
  $("#name2").text(name)
})"$
	Dim script4 As String = $"$(document).on("click", "#add", function (e) {
  var form = $("#add_form")
  form.validate({
    rules: {
      name: {
        required: true
      },
      action: "required"
    },
    messages: {
      name: {
        required: "Please enter Category Name"
      },
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault()
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
      $.ajax({
        type: "POST",
        url: "/${Main.conf.ApiName}/categories",
        data: data,
        dataType: "json",
        success: function (response) {
          $("#new").modal("hide")
          ${ReturnAlertScript(SimpleResponse.Enable, "New category added !", 201)}
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError)
        }
      })
      // return false // required to block normal submit since you used ajax
    }
  })
})"$
	Dim script5 As String = $"$(document).on("click", "#update", function (e) {
  var form = $("#update_form")
  form.validate({
    rules: {
      name: {
        required: true
      },
      action: "required"
    },
    messages: {
      name: {
        required: "Please enter Category Name"
      },
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault()
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
      $.ajax({
        data: data,
        dataType: "json",
        type: "put",
        url: "/${Main.conf.ApiName}/categories/" + $("#id1").val(),
        success: function (response) {
          $("#edit").modal("hide")
		  ${ReturnAlertScript2(SimpleResponse.Enable, "Category updated successfully !", 200)}
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError)
        }
      })
      // return false // required to block normal submit since you used ajax
    }
  })
})"$
	Dim script6 As String = $"$(document).on("click", "#remove", function (e) {
  e.preventDefault()
  var form = $("#delete_form")
  var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
  $.ajax({
    data: data,
    dataType: "json",
    type: "delete",
    url: "/${Main.conf.ApiName}/categories/" + $("#id2").val(),
    success: function (response) {
      $("#delete").modal("hide")
	  ${ReturnAlertScript3(SimpleResponse.Enable, "Category deleted successfully !", 200)}
    },
    error: function (xhr, ajaxOptions, thrownError) {
      alert(thrownError)
    }
  })
})"$
	Dim script7 As String = $"function convertFormToJSON(form) {
  const array = $(form).serializeArray() // Encodes the set of form elements as an array of names and values.
  const json = {}
  $.each(array, function () {
    json[this.name] = this.value || ""
  })
  return json
}"$
	
	Dim CategoryFile As String = $"$(document).ready(function () {
${script1}
})

${script2}

${script3}

${script4}

${script5}

${script6}

${script7}"$
	File.WriteString(DirName, FileName, CategoryFile)
End Sub

Public Sub GenerateJSFileForHelp (DirName As String, FileName As String, SimpleResponse As SimpleResponse)
	Dim script1 As String = $"// Button click event for all verbs
$(".get, .post, .put, .delete").click(function (e) {
	e.preventDefault()
	const element = $(this)
	const id = element.attr("id").substring(3)
	makeApiRequest(id)
})"$
	Dim script2 As String = $"// Function to set options
function setOptions(id) {
	const element = $("#btn" + id)
	const headers = setHeaders(element)
	switch (true) {
		case element.hasClass("get"):
			return {
				type: "GET",
				headers: headers,
				${ReturnSuccessScript(SimpleResponse.Enable, False)}
				error: function (xhr, textStatus, errorThrown) {
					var content = xhr.responseText
					$("#alert" + id).fadeOut("fast", function () {
						$("#response" + id).val(content)
						$("#alert" + id).html(xhr.status + " " + errorThrown)
						$("#alert" + id).removeClass("alert-success")
						$("#alert" + id).addClass("alert-danger")
						$("#alert" + id).fadeIn()
					})
				}
			}
			break
		case element.hasClass("post"):
			return {
				type: "POST",
				data: $("#body" + id).val(),
				dataType: "json",
				headers: headers,
				${ReturnSuccessScript(SimpleResponse.Enable, True)}
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#alert" + id).fadeOut("fast", function () {
						$("#response" + id).val(content)
						$("#alert" + id).html(xhr.status + " " + thrownError)
						$("#alert" + id).removeClass("alert-success")
						$("#alert" + id).addClass("alert-danger")
						$("#alert" + id).fadeIn()
					})
				}
			}
			break
		case element.hasClass("put"):
			return {
				type: "PUT",
				data: $("#body" + id).val(),
				dataType: "json",
				headers: headers,
				${ReturnSuccessScript(SimpleResponse.Enable, False)}
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#alert" + id).fadeOut("fast", function () {
						$("#response" + id).val(content)
						$("#alert" + id).html(xhr.status + " " + thrownError)
						$("#alert" + id).removeClass("alert-success")
						$("#alert" + id).addClass("alert-danger")
						$("#alert" + id).fadeIn()
					})
				}
			}
			break
		case element.hasClass("delete"):
			return {
				type: "DELETE",
				headers: headers,
				${ReturnSuccessScript(SimpleResponse.Enable, False)}
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#alert" + id).fadeOut("fast", function () {
						$("#response" + id).val(content)
						$("#alert" + id).html(xhr.status + " " + thrownError)
						$("#alert" + id).removeClass("alert-success")
						$("#alert" + id).addClass("alert-danger")
						$("#alert" + id).fadeIn()
					})
				}
			}
			break
		default: // unsupported verbs
			return {}
	}
}"$
	Dim script3 As String = $"// Function to return headers base on button class
function setHeaders(element) {
	// Using switch case for readibility
	switch (true) {
		case element.hasClass("basic"):
			return {
				"Accept": "application/json",
				"Authorization": "Basic " + btoa(localStorage.getItem("client_id") + ":" + localStorage.getItem("client_secret"))
			}
			break
		case element.hasClass("token"):
			return {
				"Accept": "application/json",
				"Authorization": "Bearer " + localStorage.getItem("access_token")
			}
			break
		default:
			return {
				"Accept": "application/json"
			}
	}
}"$
	Dim script4 As String = $"// Function to make API call using Ajax
function makeApiRequest(id) {
	const url = $("#path" + id).val()
	const options = setOptions(id)
	$.ajax(url, options)
}"$
	
	Dim HelpFile As String = $"${script1}
${script2}
${script3}
${script4}"$
	File.WriteString(DirName, FileName, HelpFile)
End Sub

Public Sub GenerateJSFileForSearch (DirName As String, FileName As String, SimpleResponse As SimpleResponse)
	Dim jsonResponse As String = "response.r"
	If SimpleResponse.Enable Then
		If SimpleResponse.Format = "Map" Then
			jsonResponse = "response." & SimpleResponse.DataKey
		Else
			jsonResponse = "response"
		End If
	End If
	Dim script1 As String = $"  $.getJSON("/${Main.conf.ApiName}/categories", function (response) {
    var item = ${jsonResponse}
    var $category1 = $("#category1")
    var $category2 = $("#category2")
    $.each(item, function (i, category) {
      $category1.append($("<option />").val(category.id).text(category.category_name))
      $category2.append($("<option />").val(category.id).text(category.category_name))
    })
  })"$
	Dim script2 As String = $"  $.getJSON("/${Main.conf.ApiName}/find", function (response) {
    var tbl_head = ""
    var tbl_body = ""
    if (${jsonResponse}.length) {
      tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>"
      tbl_body += "<tbody>"
      $.each(${jsonResponse}, function () {
        var col_id = ""
        var col_code = ""
        var col_category = ""
        var col_name = ""
        var col_price = ""
        var col_edit = ""
        var id
        var code
        var name
        var price
        var catid
        $.each(this, function (key, value) {
          if (key == "id") {
            col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
            id = value
          }
          else if (key == "product_code") {
            col_code = "<td class=\"align-middle\">" + value + "</td>"
            code = value
          }
          else if (key == "category_name") {
            col_category = "<td class=\"align-middle\">" + value + "</td>"
          }
          else if (key == "product_name") {
            col_name = "<td class=\"align-middle\">" + value + "</td>"
            name = value
          }
          else if (key == "product_price") {
            col_price = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>"
            price = value
          }
          else if (key == "category_id") {
            catid = value
          }
        })
        col_edit = "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>"
        tbl_body += "<tr>" + col_id + col_code + col_category + col_name + col_price + col_edit + "</tr>"
      })
      tbl_body += "</tbody>"
    }
    else {
      tbl_body = "<tr><td>No results</td></tr>"
    }
    $("#results table").html(tbl_head + tbl_body)
  })"$
	Dim script3 As String = $"$("#btnsearch").click(function (e) {
  e.preventDefault()
  var form = $("#search_form")
  var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
  $.ajax({
    type: "POST",
    url: "/${Main.conf.ApiName}/find",
    data: data,
    dataType: "json",
	${ReturnSuccessTableScript(SimpleResponse.Enable, jsonResponse)}
    error: function (xhr, ajaxOptions, thrownError) {
      $(".alert").html(thrownError)
      $(".alert").fadeIn()
    }
  })
})"$
	Dim script4 As String = $"$(document).on("click", ".edit", function (e) {
  var id = $(this).attr("data-id")
  var category = $(this).attr("data-category")
  var code = $(this).attr("data-code")
  var name = $(this).attr("data-name")
  var price = $(this).attr("data-price").replace(",", "")
  $("#id1").val(id)
  $("#category2").val(category)
  $("#code1").val(code)
  $("#name1").val(name)
  $("#price1").val(price)
})"$
	Dim script5 As String = $"$(document).on("click", ".delete", function (e) {
  var id = $(this).attr("data-id")
  var code = $(this).attr("data-code")
  var name = $(this).attr("data-name")
  $("#id2").val(id)
  $("#code_name").text("(" + code + ") " + name)
})"$
	Dim script6 As String = $"$(document).on("click", "#add", function (e) {
  var form = $("#add_form")
  form.validate({
    rules: {
      code: {
        required: true,
        minlength: 3
      },
      name: {
        required: true
      },
      action: "required"
    },
    messages: {
      code: {
        required: "Please enter Product Code",
        minlength: "Value must be at least 3 characters"
      },
      name: {
        required: "Please enter Product Name"
      },
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault()
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
      $.ajax({
        type: "POST",
        url: "/${Main.conf.ApiName}/products",
        data: data,
        dataType: "json",
        success: function (response) {
          $("#new").modal("hide")
		  ${ReturnAlertScript2(SimpleResponse.Enable, "New product added !", 201)}
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError)
        }
      })
    }
  })
})"$
	Dim script7 As String = $"$(document).on("click", "#update", function (e) {
  var form = $("#update_form")
  form.validate({
    rules: {
      code: {
        required: true,
        minlength: 3
      },
      name: {
        required: true
      },
      action: "required"
    },
    messages: {
      code: {
        required: "Please enter Product Code",
        minlength: "Value must be at least 3 characters"
      },
      name: {
        required: "Please enter Product Name"
      },
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault()
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
      $.ajax({
        data: data,
        dataType: "json",
        type: "put",
        url: "/${Main.conf.ApiName}/products/" + $("#id1").val(),
        success: function (response) {
          $("#edit").modal("hide")
		  ${ReturnAlertScript2(SimpleResponse.Enable, "Product updated successfully !", 200)}
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError)
        }
      })
    }
  })
})"$
	Dim script8 As String = $"$(document).on("click", "#remove", function (e) {
  e.preventDefault()
  var form = $("#delete_form")
  var data = JSON.stringify(convertFormToJSON(form), undefined, 2)
  $.ajax({
    data: data,
    dataType: "json",
    type: "delete",
    url: "/${Main.conf.ApiName}/products/" + $("#id2").val(),
    success: function (response) {
      $("#delete").modal("hide")
	  ${ReturnAlertScript3(SimpleResponse.Enable, "Product deleted successfully !", 200)}
    },
    error: function (xhr, ajaxOptions, thrownError) {
      alert(thrownError)
    }
  })
})"$
	Dim script9 As String = $"function convertFormToJSON(form) {
  const array = $(form).serializeArray() // Encodes the set of form elements as an array of names and values.
  const json = {}
  $.each(array, function () {
    json[this.name] = this.value || ""
  })
  return json
}"$
  
	Dim SearchFile As String = $"$(document).ready(function () {
${script1}

${script2}
})

${script3}

${script4}

${script5}

${script6}

${script7}

${script8}

${script9}"$
	File.WriteString(DirName, FileName, SearchFile)
End Sub