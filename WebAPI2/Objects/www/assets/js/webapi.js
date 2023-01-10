$("#btnLogin").click(function (e) {
    e.preventDefault();
    $.ajax({
        type: "POST",
        url: "api/account/login",
        dataType: 'json',
        contentType: 'application/json',
        // data: JSON.stringify(data),
        data: JSON.stringify({ "email": $('#email').val(), "password": $('#password').val() }),
        success: function (response) {
            // console.log(response);
            if (response.s == "ok") {
                if (response.r.length > 0) {
                    console.log(response.r[0].access_token);
                    // save Access Token to local storage for JavaScript access
                    // warning: using local storage has potential risk to XSS attack!
                    localStorage.setItem('access_token', response.r[0].access_token);
                }
                window.location = '/dashboard';
            }
            // else if (response.a == 401) {
            //     // Attempt to refresh token
            //     $.ajax({
            //         type: "POST",
            //         url: "api/account/refresh-token",
            //         dataType: 'json',
            //         contentType: 'application/json',
            //         // data: JSON.stringify(data),
            //         data: JSON.stringify({ "refresh-token": $('#password').val() }),
            //         success: function (response) {
            //             console.log(response);
            //             if (response.s == "ok") {
            //                 console.log(response.r);
            //                 window.location = '/dashboard';
            //             }
            //             else {
            //                 $(".alert").html(response.e);
            //                 $(".alert").fadeIn();
            //             }
            //         }
            //     });
            // }
            else {
                $(".alert").html(response.e);
                $(".alert").fadeIn();
            }
        },
        error: function (xhr, ajaxOptions, thrownError) {
            $(".alert").html(thrownError);
            $(".alert").fadeIn();
        }
    });
});