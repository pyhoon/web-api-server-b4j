// Button click event for all verbs
$(".get, .post, .put, .delete").click(function (e) {
	e.preventDefault()
	const element = $(this)
	makeApiRequest(element)
})
// Function to set options
function setOptions(element) {
	var id = element.attr("id")
	var headers = setHeaders(element)

	switch(true) {
		case element.hasClass("post"):
			return {
				type: "POST",
				data: $("#body"+id).val(),
				dataType: "json",
				headers: headers,
				success: function (data, textStatus, xhr) {
					var content = JSON.stringify(data, undefined, 2)
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + textStatus)
					$("#alert" + id).removeClass("alert-danger")
					$("#alert" + id).addClass("alert-success")
					$("#alert" + id).fadeIn()
				},
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + thrownError)
					$("#alert" + id).removeClass("alert-success")
					$("#alert" + id).addClass("alert-danger")
					$("#alert" + id).fadeIn()
				}
			}
			break
		case element.hasClass("put"):
			return {
				type: "PUT",
				data: $("#body"+id).val(),
				dataType: "json",
				headers: headers,
				success: function (data, textStatus, xhr) {
					var content = JSON.stringify(data, undefined, 2)
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + textStatus)
					$("#alert" + id).removeClass("alert-danger")
					$("#alert" + id).addClass("alert-success")
					$("#alert" + id).fadeIn()
				},
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + thrownError)
					$("#alert" + id).removeClass("alert-success")
					$("#alert" + id).addClass("alert-danger")
					$("#alert" + id).fadeIn()
				}
			}
			break
		case element.hasClass("delete"):
			return {
				type: "DELETE",
				headers: headers,
				success: function (data, textStatus, xhr) {
					var content = JSON.stringify(data, undefined, 2)
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + textStatus)
					$("#alert" + id).removeClass("alert-danger")
					$("#alert" + id).addClass("alert-success")
					$("#alert" + id).fadeIn()
				},
				error: function (xhr, textStatus, thrownError) {
					var content = xhr.responseText
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + thrownError)
					$("#alert" + id).removeClass("alert-success")
					$("#alert" + id).addClass("alert-danger")
					$("#alert" + id).fadeIn()
				}
			}
			break
		case element.hasClass("get"):
			return {
				type: "GET",
				headers: headers,
				success: function (data, textStatus, xhr) {
					var content = JSON.stringify(data, undefined, 2)
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + textStatus)
					$("#alert" + id).removeClass("alert-danger")
					$("#alert" + id).addClass("alert-success")
					$("#alert" + id).fadeIn()
				},
				error: function (xhr, textStatus, errorThrown) {
					var content = xhr.responseText
					$("#response" + id).val(content)
					$("#alert" + id).html(xhr.status + ' ' + errorThrown)
					$("#alert" + id).removeClass("alert-success")
					$("#alert" + id).addClass("alert-danger")
					$("#alert" + id).fadeIn()
				}
			}
			break
		default: // unsupported verbs
			return {}
	}
}
// Function to return headers base on button class
function setHeaders(element) {
	// Using switch case for readibility
	switch (true) {
		case element.hasClass("basic"):
			return {
				"Accept": "application/json",
				"Authorization": "Basic " + btoa(localStorage.getItem('client_id') + ":" + localStorage.getItem('client_secret'))
			}
			break
		case element.hasClass("token"):
			return {
				"Accept": "application/json",
				"Authorization": "Bearer " + localStorage.getItem('access_token')
			}
			break
		default:
			return {
				"Accept": "application/json"
			}
	}
}
// Function to make API call using Ajax
function makeApiRequest(element) {
	const id = element.attr("id")
	const url = $("#path" + id).val()
	const options = setOptions(element)
	$.ajax(url, options)
}