var Handlebars = require("handlebars");

WT.listeners = function() {
  $(".another-query").on("click", startOver);
};

WT.formSubmit = function(e) {
  if(!this.composer.value) {
    return alert('Composer is required!');
  }

  var composer = this.composer.value;

  history.pushState({}, composer + " - Sound Search from MusikAnimal", WT.path + "?" + this.params);
};

function startOver() {
  $(".output").hide();
  $(".loading").hide();
  $(".result-block").html("").hide();
  $("input[type=checkbox]").prop("checked", false);
  $("input[type=text]").val("");
  $("#composer").val("");
  $("form").removeClass("busy hide");
  history.pushState({}, "Sound Search from MusikAnimal", WT.path);
}
