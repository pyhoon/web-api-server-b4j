$(document).ready(function () {
  $.getJSON("/web/category/sort/name", function (result) {
    var item = result.r;
    var $category = $("#category");     // category dropdown list for add form
    var $category1 = $("#category1");   // category dropdown list for edit form
    $.each(item, function (i, category) {
      $category.append($("<option />").val(category.aa).text(category.bb));
      $category1.append($("<option />").val(category.aa).text(category.bb));
    });
  });

  $.getJSON("/web/?default=1", function (response) {
    // var tbl_head = "";
    // var tbl_body = "";
    var cards = "";
    if (response.r.length) {
      // tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Slug</th><th>Category</th><th>Title</th><th>Body</th><th style=\"width: 90px\">Actions</th></thead>";
      // tbl_body += "<tbody>";
      $.each(response.r, function () {
        // var tbl_row = "";
        var id;
        var slug;
        var category;
        var title;
        var body;
        var status;
        var created_date;
        var catid;
        $.each(this, function (key, value) {
          if (key == "aa") {
            // tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            id = value;
          }
          else if (key == "bb") {
            // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            slug = value;
          }
          else if (key == "cc") {
            // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            category = value;
          }
          else if (key == "dd") {
            // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            title = value;
          }
          else if (key == "ee") {
            // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            body = value;
          }
          else if (key == "ff") {
            status = value;
          }
          else if (key == "gg") {
            created_date = value;
          }
          else if (key == "hh") {
            catid = value;
          }          
          else {
            // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
          }
        });
        // tbl_row += "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\"  data-body=\"" + body + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\" title=\"Delete\"></i></a></td>";
        // tbl_body += "<tr>" + tbl_row + "</tr>";
        cards += "<div class=\"card m-3\">";
        cards += "<div class=\"card-body\">";
        cards += "<h3 class=\"card-title\">" + title + "</h3>";
        // cards += "<p class=\"card-text\">" + slug + "</p>";
        cards += "<p class=\"card-text\">" + body.replace(/\n/g, "<br />") + "</p>";
        cards += "<div>\
        <a href=\"#edit\" class=\"edit text-primary mx-2\" data-toggle=\"modal\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\" data-body=\"" + body + "\" data-status=\"" + status + "\"><i class=\"fa fa-pen\" data-toggle=\"tooltip\" title=\"Edit\"></i> Edit</a> \
        <a href=\"#delete\" class=\"delete text-danger mx-2\" data-toggle=\"modal\" data-id=\"" + id + "\" data-title=\"" + title + "\"><i class=\"fa fa-trash\" data-toggle=\"tooltip\" title=\"Delete\"></i> Delete</a></div>";
        cards += "</div>";
        cards += "<div class=\"card-footer text-muted\"><em>posted in " + category + " on " + created_date + "</em></div>";
        cards += "</div>";        
      });
      // tbl_body += "</tbody>";
    }
    else {
      // tbl_body = "<tr><td>No results</td></tr>";
      cards += "<div class=\"card m-3\">";
      cards += "<div class=\"card-body\">No contents</div>";
      cards += "</div>"; 
    }
    // $("#results table").html(tbl_head + tbl_body);
    $("#results").html(cards);
  });
});

$("#btnsearch").click(function (e) {
  e.preventDefault();
  $.ajax({
    type: "POST",
    url: "/web/",
    data: $("form").serialize(),
    success: function (response) {
      // console.log(response);
      if (response.s == "ok") {
        // var tbl_head = "";
        //var tbl_body = "";
        var cards = "";
        if (response.r.length) {
          //tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Slug</th><th>Category</th><th>Title</th><th>Body</th><th style=\"width: 90px\">Actions</th></thead>";
          //tbl_body += "<tbody>";
          $.each(response.r, function () {
            // var tbl_row = "";            
            var id;
            var slug;
            var category;
            var title;
            var body;
            var status;
            var created_date;
            var catid;
            $.each(this, function (key, value) {
              if (key == "aa") {
                // tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
                id = value;
              }
              else if (key == "bb") {
                // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                slug = value;
              }
              else if (key == "cc") {
                // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                category = value;
              }
              else if (key == "dd") {
                // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                title = value;
              }
              else if (key == "ee") {
                // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                body = value;
              }
              else if (key == "ff") {
                status = value;
              }
              else if (key == "gg") {
                created_date = value;
              }
              else if (key == "hh") {
                catid = value;
              }              
              else {
                // tbl_row += "<td class=\"align-middle\">" + value + "</td>";
              }
            });
            // tbl_row += "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\"  data-body=\"" + body + "\" title=\"Edit\"></i> Edit</a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\" title=\"Delete\"></i> Delete</a></td>";
            // tbl_body += "<tr>" + tbl_row + "</tr>";
            cards += "<div class=\"card m-3\">";
            cards += "<div class=\"card-body\">";
            cards += "<h3 class=\"card-title\">" + title + "</h3>";
            // cards += "<p class=\"card-text\">" + slug + "</p>";
            cards += "<p class=\"card-text\">" + body.replace(/\n/g, "<br />") + "</p>";
            cards += "<div>\
            <a href=\"#edit\" class=\"edit text-primary mx-2\" data-toggle=\"modal\" data-id=\"" + id + "\" data-slug=\"" + slug + "\" data-category=\"" + catid + "\" data-title=\"" + title + "\" data-body=\"" + body + "\" data-status=\"" + status + "\"><i class=\"fa fa-pen\" data-toggle=\"tooltip\" title=\"Edit\"></i> Edit</a> \
            <a href=\"#delete\" class=\"delete text-danger mx-2\" data-toggle=\"modal\" data-id=\"" + id + "\" data-title=\"" + title + "\"><i class=\"fa fa-trash\" data-toggle=\"tooltip\" title=\"Delete\"></i> Delete</a></div>";
            cards += "</div>";
            cards += "<div class=\"card-footer text-muted\"><em>posted in " + category + " on " + created_date + "</em></div>";
            cards += "</div>";
          });
          // tbl_body += "</tbody>";
        }
        else {
          // tbl_body = "<tr><td>No results</td></tr>";
          cards += "<div class=\"card m-3\">";
          cards += "<div class=\"card-body\">No contents</div>";
          cards += "</div>"; 
        }
        // $("#results table").html(tbl_head + tbl_body);        
        $("#results").html(cards);
      }
      else {
        $(".alert").html(response.e);
        $(".alert").fadeIn();
      }
    },
    error: function (xhr, ajaxOptions, thrownError) {
      $(".alert").html(xhr.status + ' ' + thrownError);
      $(".alert").fadeIn();
    }
  });
});

$(document).on('click', '.edit', function (e) {
  var id = $(this).attr("data-id");
  var category = $(this).attr("data-category");
  var slug = $(this).attr("data-slug");
  var title = $(this).attr("data-title");
  var body = $(this).attr("data-body");
  var status = $(this).attr("data-status");
  $('#id1').val(id);
  $('#category1').val(category);
  $('#slug1').val(slug);
  $('#title1').val(title);
  $('#body1').val(body);
  $('#status1').val(status);
});

$(document).on('click', '.delete', function (e) {
  var id = $(this).attr("data-id");
  var title = $(this).attr("data-title");
  $('#id2').val(id);
  $('#title2').text(title);
});

$(document).on('click', '#add', function (e) {
  var form = $("#add_form");
  form.validate({
    rules: {
      slug: {
        required: true,
        minlength: 3
      },
      title: {
        required: true
      },
      body: {
        required: true
      },
      action: "required"
    },
    messages: {
      slug: {
        required: "Please enter Post Slug",
        minlength: "Value must be at least 3 characters"
      },
      title: {
        required: "Please enter Post Title"
      },
      body: {
        required: "Please enter Post Body"
      },
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      console.log(data);
      $.ajax({
        data: data,
        dataType: "json",
        type: "post",
        url: "/web/api/v2/post",
        success: function (response) {
          $('#new').modal('hide');
          if (response.a == 201) {
            alert('New Post created!');
            location.reload();
          }
          else {
            alert(response.a + ' ' + response.e);
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(xhr.status + ' ' + thrownError);
        }
      });
      // return false; // required to block normal submit since you used ajax
    }
  });
});

$(document).on('click', '#update', function (e) {
  var form = $("#update_form");
  form.validate({
    rules: {
      slug: {
        required: true,
        minlength: 3
      },
      title: {
        required: true
      },
      body: {
        required: true
      },      
      action: "required"
    },
    messages: {
      slug: {
        required: "Please enter Post Slug",
        minlength: "Value must be at least 3 characters"
      },
      title: {
        required: "Please enter Post Title"
      },
      body: {
        required: "Please enter Post Body"
      },      
      action: "Please provide some data"
    },
    submitHandler: function (form) {
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      $.ajax({
        data: data,
        dataType: "json",
        type: "put",
        url: "/web/api/v2/post/" + $('#id1').val(),
        success: function (response) {
          $('#edit').modal('hide');
          if (response.a == 200) {
            alert('Post updated successfully !');
            location.reload();
          }
          else {
            alert(response.a + ' ' + response.e);
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(xhr.status + ' ' + thrownError);
        }
      });
      // return false; // required to block normal submit since you used ajax
    }
  });
});

$(document).on('click', '#remove', function (e) {
  e.preventDefault();
  var form = $("#delete_form");
  var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
  $.ajax({
    data: data,
    dataType: "json",
    type: "delete",
    url: "/web/api/v2/post/" + $('#id2').val(),
    success: function (response) {
      $('#delete').modal('hide');
      if (response.a == 200) {
        alert('Post deleted successfully !');
        location.reload();
      }
      else {
        alert(response.a + ' ' + response.e);
      }
    },
    error: function (xhr, ajaxOptions, thrownError) {
      alert(xhr.status + ' ' + thrownError);
    }
  });
});

function convertFormToJSON(form) {
  const array = $(form).serializeArray(); // Encodes the set of form elements as an array of names and values.
  const json = {};
  $.each(array, function () {
    json[this.name] = this.value || "";
  });
  return json;
}