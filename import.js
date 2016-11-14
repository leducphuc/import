var import_data = function() {
  $(".file-select").bind("change", function() {
    var file_extension = this.files[0].name.split(".").pop().toLowerCase();
    var allowed_file, message;
    if($(this).attr("id") == "file-select-employee") {
      allowed_file = ["csv"];
      message = I18n.t("imports.allowed_csv")
    }
    else {
      allowed_file = ["csv", "json"];
      message = I18n.t("imports.allowed_csv_json")
    }

    var found_index = $.inArray(file_extension, allowed_file);
    if(found_index < 0) {
      alert(message);
      $(this).val("");
    }
  });
};

$(document).ready(function(){
  import_data();
  $("#form-submit-btn").click(function(){
    var file_inputs = $("input[type=file]");

    for (var i = 0; i < file_inputs.length; i++){
      if (file_inputs[i].value === "")
        file_inputs[i].disabled = true;
      else{
        var model = $("#" + file_inputs[i].id).data("model");

        $("#check-box-tag-file-select-" + model).prop("checked", true);
        $("#loading-image-" + model).removeClass("hidden");
      }
    }

    $("form").submit();
  });

  $(document).on("change", ".check-box", function(){
    $(".check-box").not(this).prop("checked", false);
  });

  $("#employees-selectbox").select2();
});
