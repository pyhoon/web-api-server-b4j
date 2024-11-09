$(document).ready(function () {
  $.getJSON("/api/categories", function (response) {
    var item = response;
    var $category1 = $("#category1");
    var $category2 = $("#category2");
    $.each(item, function (i, category) {
      $category1.append($("<option />").val(category.id).text(category.category_name));
      $category2.append($("<option />").val(category.id).text(category.category_name));
    });
  });

  $.getJSON("/api/find", function (response) {
    var tbl_head = "";
    var tbl_body = "";
    if (response.length) {
      tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>";
      tbl_body += "<tbody>";
      $.each(response, function () {
        var col_id = "";
        var col_code = "";
        var col_category = "";
        var col_name = "";
        var col_price = "";
        var col_edit = "";
        var id;
        var code;
        var name;
        var price;
        var catid;
        $.each(this, function (key, value) {
          if (key == "id") {
            col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            id = value;
          }
          else if (key == "product_code") {
            col_code = "<td class=\"align-middle\">" + value + "</td>";
            code = value;
          }
          else if (key == "category_name") {
            col_category = "<td class=\"align-middle\">" + value + "</td>";
          }
          else if (key == "product_name") {
            col_name = "<td class=\"align-middle\">" + value + "</td>";
            name = value;
          }
          else if (key == "product_price") {
            col_price = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            price = value;
          }
          else if (key == "category_id") {
            catid = value;
          }
        });
        col_edit = "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\"  data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>";
        tbl_body += "<tr>" + col_id + col_code + col_category + col_name + col_price + col_edit + "</tr>";
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
  var form = $("#search_form");
  var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
  $.ajax({
    type: "POST",
    url: "/api/find",
    data: data,
    dataType: "json",
    success: function (response) {
      //console.log(response);
      var tbl_head = "";
      var tbl_body = "";
      if (response.length) {
        tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Code</th><th>Category</th><th>Name</th><th style=\"text-align: right\">Price</th><th style=\"width: 90px\">Actions</th></thead>";
        tbl_body += "<tbody>";
        $.each(response, function () {
          var col_id = "";
          var col_code = "";
          var col_category = "";
          var col_name = "";
          var col_price = "";
          var col_edit = "";
          var id;
          var code;
          var name;
          var price;
          var catid;
          $.each(this, function (key, value) {
            if (key == "id") {
              col_id = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
              id = value;
            }
            else if (key == "product_code") {
              col_code = "<td class=\"align-middle\">" + value + "</td>";
              code = value;
            }
            else if (key == "category_name") {
              col_category = "<td class=\"align-middle\">" + value + "</td>";
            }
            else if (key == "product_name") {
              col_name = "<td class=\"align-middle\">" + value + "</td>";
              name = value;
            }
            else if (key == "product_price") {
              col_price = "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
              price = value;
            }
            else if (key == "category_id") {
              catid = value;
            }
          });
          col_edit = "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\"  data-price=\"" + price + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-code=\"" + code + "\" data-category=\"" + catid + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>";
          tbl_body += "<tr>" + col_id + col_code + col_category + col_name + col_price + col_edit + "</tr>";
        });
        tbl_body += "</tbody>";
      }
      else {
        tbl_body = "<tr><td>No results</td></tr>";
      }
      $("#results table").html(tbl_head + tbl_body);
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
  $('#category2').val(category);
  $('#code1').val(code);
  $('#name1').val(name);
  $('#price1').val(price);
});

$(document).on('click', '.delete', function (e) {
  var id = $(this).attr("data-id");
  var code = $(this).attr("data-code");
  var name = $(this).attr("data-name");
  $('#id2').val(id);
  $('#code_name').text("(" + code + ") " + name);
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
        type: "POST",
        url: "/api/products",
        data: data,
        dataType: "json",
        success: function (response) {
          $('#new').modal('hide');
          alert('New product added!');
          location.reload();
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
        url: "/api/products/" + $('#id1').val(),
        success: function (response) {
          $('#edit').modal('hide');
          alert('Product updated successfully !');
          location.reload();
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
    url: "/api/products/" + $('#id2').val(),
    success: function (response) {
      $('#delete').modal('hide');
      alert('Product deleted successfully !');
      location.reload();
    },
    error: function (xhr, ajaxOptions, thrownError) {
      alert(thrownError);
    }
  });
});

function convertFormToJSON(form) {
  const array = $(form).serializeArray(); // Encodes the set of form elements as an array of names and values.
  const json = {}
  $.each(array, function () {
    json[this.name] = this.value || ""
  })
  return json
}