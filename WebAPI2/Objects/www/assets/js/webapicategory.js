$(document).ready(function () {
  $.getJSON("/api/category/list", function (response) {
    var tbl_head = "";
    var tbl_body = "";
    if (response.r.length) {
      tbl_head = "<thead class=\"bg-light\"><th style=\"text-align: right; width: 60px\">#</th><th>Name</th><th style=\"width: 90px\">Actions</th></thead>";
      tbl_body += "<tbody>";
      $.each(response.r, function () {
        var tbl_row = "";
        var id;
        var name;
        $.each(this, function (key, value) {
          if (key == "aa") {
            tbl_row += "<td class=\"align-middle\" style=\"text-align: right\">" + value + "</td>";
            id = value;
          }
          else if (key == "bb") {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
            name = value;
          }
          else {
            tbl_row += "<td class=\"align-middle\">" + value + "</td>";
          }
        });
        tbl_row += "<td><a href=\"#edit\" class=\"text-primary mx-2\" data-toggle=\"modal\"><i class=\"edit fa fa-pen\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-name=\"" + name + "\" title=\"Edit\"></i></a> <a href=\"#delete\" class=\"text-danger mx-2\" data-toggle=\"modal\"><i class=\"delete fa fa-trash\" data-toggle=\"tooltip\" data-id=\"" + id + "\" data-name=\"" + name + "\" title=\"Delete\"></i></a></td>";
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

$(document).on('click', '.edit', function (e) {
  var id = $(this).attr("data-id");
  var name = $(this).attr("data-name");
  $('#id1').val(id);
  $('#name1').val(name);
});

$(document).on('click', '.delete', function (e) {
  var id = $(this).attr("data-id");
  var name = $(this).attr("data-name");
  $('#id2').val(id);
  $('#name2').text(name);
});

$(document).on('click', '#add', function (e) {
  var form = $("#add_form");
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
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      $.ajax({
        data: data,
        dataType: "json",
        type: "post",
        url: "/api/category",
        success: function (response) {
          $('#new').modal('hide');
          if (response.a == 201) {
            alert('Category added!');
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
      e.preventDefault();
      var data = JSON.stringify(convertFormToJSON(form), undefined, 2);
      $.ajax({
        data: data,
        dataType: "json",
        type: "put",
        url: "/api/category/" + $('#id1').val(),
        success: function (response) {
          $('#edit').modal('hide');
          if (response.a == 200) {
            alert('Category updated successfully !');
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
    url: "/api/category/" + $('#id2').val(),
    success: function (response) {
      $('#delete').modal('hide');
      if (response.a == 200) {
        alert('Category deleted successfully !');
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