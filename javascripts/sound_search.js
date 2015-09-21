var Handlebars = require("handlebars");
var files = require("../views/sound_search/files.handlebars");

WT.listeners = function() {
  $(".another-query").on("click", startOver);

  $("#nosoundlist_toggle").on("click", function() {
    if(this.checked) {
      $(".sound-list-pages").show();
    } else {
      $(".sound-list-pages").hide();
    }
  });
};

WT.formSubmit = function(e) {
  if(!this.composer.value) {
    return alert('Composer is required!');
  }

  var composer = this.composer.value;

  history.pushState({}, composer + " - Sound Search from MusikAnimal", WT.path + "?" + this.params);

  WT.api("", this.params).success(function(data) {
    data.files = _.map(data.files, function(file) {
      return _.extend(data.files, {
        title: file.title,
        source: escape(file.title.replace("File:", "").replace(/ /g,"_"))
      });
    });

    data.file_count = data.files.length;
    data.plural = files.length > 1;
    data.project_path = WT.projectPath;

    $(".files").append(
      files(data)
    );

    $(".loading").hide();
    $("form").addClass("hide");
    $(".output").show();
  }).error(function() {
    alert("Something went wrong. Sorry.");
    startOver();
  });
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
