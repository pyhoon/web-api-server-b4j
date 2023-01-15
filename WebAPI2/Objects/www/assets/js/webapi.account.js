$("#btnLogin").click(function (e) {
    e.preventDefault();
    console.log("login in...");
    $.ajax({
        type: "POST",
        url: "/web/api/v2/account/login",
        dataType: 'json',
        contentType: 'application/json',
        // data: JSON.stringify(data),
        data: JSON.stringify({ "email": $('#email').val(), "password": $('#password').val() }),
        success: function (response) {
            console.log(response);
            if (response.s == "ok") {
                if (response.r.length > 0) {
                    console.log(response.r[0].access_token);
                    // save Access Token to local storage for JavaScript access
                    // warning: using local storage has potential risk to XSS attack!
                    localStorage.setItem('access_token', response.r[0].access_token);
                }
                $("#alert").removeClass("alert-danger");
                $("#alert").addClass("alert-success");
                $("#alert").html(response.m + "<br/>Page is redirecting...");
                $("#alert").fadeIn();
                // window.location = '/web/dashboard';
                redirect('/web/dashboard', 3000);
            }
            // else if (response.a == 401) {
            //     // Attempt to refresh token
            //     $.ajax({
            //         type: "POST",
            //         url: "api/v2/account/token",
            //         dataType: 'json',
            //         contentType: 'application/json',
            //         data: JSON.stringify({ "refresh-token": $('#password').val() }),
            //         success: function (response) {
            //             console.log(response);
            //             if (response.s == "ok") {
            //                 console.log(response.r);
            //                 window.location = '/dashboard';
            //             }
            //             else {
            //                 $("#alert").html(response.e);
            //                 $("#alert").fadeIn();
            //             }
            //         }
            //     });
            // }
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
            $("#alert").fadeIn();
        }
    });
});

$("#btnRegister").click(function (e) {
    e.preventDefault();
    $.ajax({
        type: "POST",
        url: "/web/api/v2/account/register",
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({ "name": $('#name').val(), "email": $('#email').val(), "password": $('#password').val() }),
        success: function (response) {
            console.log(response);
            if (response.s == "ok") {
                $("#alert").removeClass("alert-danger");
                $("#alert").addClass("alert-success");
                $("#alert").html(response.m + "<br/>Page is redirecting...");
                $("#alert").fadeIn();
                redirect('/web/login', 5000);
            }
            else {
                $("#alert").removeClass("alert-success");
                $("#alert").addClass("alert-danger");
                $("#alert").html(response.e);
                $("#alert").fadeIn();
            }
        },
        error: function (xhr, ajaxOptions, thrownError) {
            $("#alert").removeClass("alert-success");
            $("#alert").addClass("alert-danger");
            $("#alert").html(xhr.status + ' ' + thrownError);
            $("#alert").fadeIn();
        }
    });
});

function redirect(path, delay) {
    setTimeout(function () { window.location = path }, delay);
}