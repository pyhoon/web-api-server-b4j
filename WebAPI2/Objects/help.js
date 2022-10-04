  $("#btnCategoryGetCategories").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnCategoryGetCategory").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnCategoryPostCategory").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnCategoryPutCategory").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "PUT",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnCategoryDeleteCategory").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "DELETE",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnProductGetProducts").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnProductGetProduct").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnProductPostProduct").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnProductPutProduct").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "PUT",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnProductDeleteProduct").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "DELETE",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnAuthenticationPostRegisterAccount").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnAuthenticationGetActivateUser").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnAuthenticationPostAuthenticate").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnAuthenticationPostRefreshToken").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnPasswordPostChangePassword").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnPasswordPostResetPassword").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "POST",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnPasswordGetConfirmReset").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnHelloGetShowMessage").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
  $("#btnHelloGetShowHelloWorld").click(function(e) {
        e.preventDefault();
	    var id = $(this).attr("id");
	    $("#response"+id).val("");
	    //console.log('url:'+$('#path'+id).val());
        $.ajax({
          type: "GET",
	      dataType: "json",
          url: $("#path"+id).val(),
          data: $("#body"+id).val(),
          success: function (data) {
            if (data.s == "ok" || data.s == "success") {
              var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.m);
              $("#alert" + id).removeClass("alert-danger");
              $("#alert" + id).addClass("alert-success");
              $("#alert" + id).fadeIn();			  
            }
            else {
              //console.log(data.e);
		      var content = JSON.stringify(data.r, undefined, 2);
              $("#response" + id).val(content);
              $("#alert" + id).html(data.a + ' ' + data.e);
              $("#alert" + id).removeClass("alert-success");
              $("#alert" + id).addClass("alert-danger");
              $("#alert" + id).fadeIn();
            }
          },
          error: function (xhr, ajaxOptions, thrownError) {
            $("#alert" + id).html('400 ' + thrownError);
            $("#alert" + id).removeClass("alert-success");
            $("#alert" + id).addClass("alert-danger");
            $("#alert" + id).fadeIn();		  
          }
        })
      })
