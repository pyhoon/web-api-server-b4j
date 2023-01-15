$("#btnSubmit").click(function (e) {
    var email = $("#email").val();
    if (email == "") {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Please Enter Your Email");
        $('#alert').fadeOut('slow', function () {
            $('#alert').fadeIn('slow');
        });
    }
    else {
        e.preventDefault();
        $.ajax({
            type: "POST",
            url: "/web/api/v2/password/forgot",
            dataType: 'json',
            contentType: 'application/json',
            // data: JSON.stringify(data),
            data: JSON.stringify({ "email": email }),
            success: function (response) {
                //console.log(response);
                if (response.s == "ok") {
                    $("#alert").removeClass("alert-danger");
                    $("#alert").addClass("alert-success");
                    $("#alert").html(response.m);
                    $("#alert").fadeIn();
                    redirect('/web/login', 5000);
                }
                else {
                    $("#alert").removeClass("alert-success");
                    $("#alert").addClass("alert-danger");
                    $("#alert").html(response.e);
                    $('#alert').fadeOut('slow', function () {
                        $('#alert').fadeIn('slow');
                    });
                }
            },
            error: function (xhr, ajaxOptions, thrownError) {
                $("#alert").removeClass("alert-success");
                $("#alert").addClass("alert-danger");
                $("#alert").html(xhr.status + ' ' + thrownError);
                $('#alert').fadeIn('slow');
            }
        });
    }
});

$("#btnConfirm").click(function (e) {
    var email = $("#email").val();
    var current = $("#current").val();
    var password = $("#password").val();
    var repeat = $("#repeat").val();
    if (email == "") {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Please Fill In Email");
        $('#alert').fadeIn('slow');
    }
    else if (current == "") {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Please Fill In Current Password");
        $('#alert').fadeIn('slow');
    }
    else if (password == "") {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Please Fill In New Password");
        $('#alert').fadeIn('slow');
    }
    else if (current == password) {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("New Password Cannot Same With Current Password");
        $('#alert').fadeIn('slow');
    }
    else if (repeat == "") {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Please Repeat New Password");
        $('#alert').fadeIn('slow');
    }
    else if (!(password == repeat)) {
        $("#alert").removeClass("alert-success");
        $("#alert").addClass("alert-danger");
        $("#alert").html("Password Not Matched");
        $('#alert').fadeIn('slow');
    }
    else {
        e.preventDefault();
        $.ajax({
            type: "POST",
            url: "/web/api/v2/password/change",
            dataType: 'json',
            contentType: 'application/json',
            // data: JSON.stringify(data),
            data: JSON.stringify({
                "email": email,
                "current": current,
                "password": password,
                "repeat": repeat
            }),
            success: function (response) {
                // console.log(response);
                if (response.s == "ok") {
                    $("#alert").removeClass("alert-danger");
                    $("#alert").addClass("alert-success");
                    $("#alert").html(response.m);
                    $("#alert").fadeIn();
                    // redirect('/web/login', 5000);
                }
                else {
                    $("#alert").removeClass("alert-success");
                    $("#alert").addClass("alert-danger");
                    $("#alert").html(response.e);
                    $('#alert').fadeOut('slow', function () {
                        $('#alert').fadeIn('slow');
                    });
                }
            },
            error: function (xhr, ajaxOptions, thrownError) {
                $("#alert").removeClass("alert-success");
                $("#alert").addClass("alert-danger");
                $("#alert").html(xhr.status + ' ' + thrownError);
                $('#alert').fadeOut('slow', function () {
                    $('#alert').fadeIn('slow');
                });
            }
        });
    }
});

function redirect(path, delay) {
    setTimeout(function () { window.location = path }, delay);
}