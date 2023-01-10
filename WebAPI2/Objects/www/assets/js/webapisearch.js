$(document).ready(function () {
  $.getJSON("/web/api/v2/categories", function (result) {
    var item = result.r;
    var $category = $("#category");     // category dropdown list for add form
    var $category1 = $("#category1");   // category dropdown list for edit form
    $.each(item, function (i, category) {
      $category.append($("<option />").val(category.id).text(category.category_name));
      $category1.append($("<option />").val(category.id).text(category.category_name));
    });
  });

  $.getJSON("/web/?default=1", function (response) {
    var tbl_head = "";
    var tbl_body = "";
    if (response.r.length) {
      tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>";
      tbl_body += "<tbody>";
      $.each(response.r, function () {
        var tbl_row = "";
        var id;
        var code;
        // var category;
        var name;
        var price;
        var catid;
        $.each(this, function (key, value) {
          if (key == "aa") {
            tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            id = value;
          }
          else if (key == "bb") {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            code = value;
          }
          else if (key == "cc") {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            // category = value;
          }
          else if (key == "dd") {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            name = value;
          }
          else if (key == "ee") {
            tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            price = value;
          }
          else if (key == "ff") {
            catid = value;
          }
          else {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
          }
        });
        tbl_row += "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\"  data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>";
        tbl_body += "<tr>" + tbl_row + "</tr>";
      });
      tbl_body += "</tbody>";
    }
    else {
      tbl_body = "<tr><td>No results</td></tr>";
    }
    $("#results table").html(tbl_head + tbl_body);
  });
});

$("#btnsearch").click(function (e) {
  e.preventDefault();
  $.ajax({
    type: "POST",
    url: "/web/",
    data: $("form").serialize(),
    success: function (response) {
      if (response.s == "ok") {
        var tbl_head = "";
        var tbl_body = "";
        if (response.r.length) {
          tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>";
          tbl_body += "<tbody>";
          $.each(response.r, function () {
            var tbl_row = "";
            var id;
            var code;
            // var category;
            var name;
            var price;
            var catid;
            $.each(this, function (key, value) {
              if (key == "aa") {
                tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
                id = value;
              }
              else if (key == "bb") {
                tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                code = value;
              }
              else if (key == "cc") {
                tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                // category = value;
              }
              else if (key == "dd") {
                tbl_row += "<td class=\"align-middle\">" + value + "</td>";
                name = value;
              }
              else if (key == "ee") {
                tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
                price = value;
              }
              else if (key == "ff") {
                catid = value;
              }
              else {
                tbl_row += "<td class=\"align-middle\">" + value + "</td>";
              }
            });
            tbl_row += "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\"  data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>";
            tbl_body += "<tr>" + tbl_row + "</tr>";
          });
          tbl_body += "</tbody>";
        }
        else {
          tbl_body = "<tr><td>No results</td></tr>";
        }
        $("#results table").html(tbl_head + tbl_body);
      }
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

$(document).on('click', '.edit', function (e) {
  var id = $(this).attr("data-id");
  var category = $(this).attr("data-category");
  var code = $(this).attr("data-code");
  var name = $(this).attr("data-name");
  var price = $(this).attr("data-price").replace(",", "");
  $('#id1').val(id);
  $('#category1').val(category);
  $('#code1').val(code);
  $('#name1').val(name);
  $('#price1').val(price);
});

$(document).on('click', '.delete', function (e) {
  var id = $(this).attr("data-id");
  var code = $(this).attr("data-code");
  var name = $(this).attr("data-name");
  $('#id2').val(id);
  $('#code_name2').text("(" + code + ") " + name);
});

$(document).on('click', '#add', function (e) {
  var form = $("#add_form");
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
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      $.ajax({
        data: data,
        dataType: "json",
        type: "post",
        url: "/web/api/v2/product",
        success: function (response) {
          $('#new').modal('hide');
          if (response.a == 201) {
            alert('New product added!');
            location.reload();
          }
          else {
            alert(response.a + ' ' + response.e);
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError);
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
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      $.ajax({
        data: data,
        dataType: "json",
        type: "put",
        url: "/web/api/v2/product/" + $('#id1').val(),
        success: function (response) {
          $('#edit').modal('hide');
          if (response.a == 200) {
            alert('Product updated successfully !');
            location.reload();
          }
          else {
            alert(response.a + ' ' + response.e);
          }
        },
        error: function (xhr, ajaxOptions, thrownError) {
          alert(thrownError);
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
    url: "/web/api/v2/product/" + $('#id2').val(),
    success: function (response) {
      $('#delete').modal('hide');
      if (response.a == 200) {
        alert('Product deleted successfully !');
        location.reload();
      }
      else {
        alert(response.a + ' ' + response.e);
      }
    },
    error: function (xhr, ajaxOptions, thrownError) {
      alert(thrownError);
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