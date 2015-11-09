var Handlebars = require("handlebars");
var fileTemplate = require("../views/sound_search/file.handlebars");
var filesTemplate = require("../views/sound_search/files.handlebars");
var fileProps = {
  audio: require("../views/sound_search/audio.handlebars"),
  backlinks: require("../views/sound_search/backlinks.handlebars"),
  info: require("../views/sound_search/info.handlebars")
};

WT.listeners = function() {
  $(".another-query").on("click", startOver);

  $("[name=list]").on("change", function(e) {
    if(this.checked && this.value === 'no_sound_list') {
      $(".sound-list-pages").css('visibility', 'visible');
    } else {
      $(".sound-list-pages").css('visibility', 'hidden');
    }
  });
};

WT.formSubmit = function(e) {
  var composer = this.composer.value;

  if(!composer) {
    return alert("Composer is required!");
  }

  $("button").blur();

  WT.updateProgress(0, "Fetching files...");

  history.pushState({}, composer + " - Sound Search from MusikAnimal", WT.path + "?" + this.params);

  WT.api("", {composer: composer}).success(function(data) {
    data.listType = this.list.value;
    if(data.listType === "unused") {
      getBacklinksOfFiles(data, 0);
    } else {
      revealData(data);
    }
    // getInfoOfFiles(data, 0);
  }.bind(this)).error(function() {
    alert("Something went wrong. Sorry.");
    startOver();
  });
};

function getBacklinksOfFiles(data, index) {
  if(index === data.files.length) {
    WT.updateProgress(100, " ");
    return revealData(data);
  }

  WT.api("backlinks/"+data.files[index].title).success(function(resp) {
    WT.updateProgress(parseInt(((index / data.files.length - 1) + 1) * 100));
    _.extendOwn(data.files[index], resp);
  }).done(function() {
    getBacklinksOfFiles(data, index + 1);
  });
}

function getInfoOfFiles(data, index) {
  if(index === data.files.length) {
    WT.updateProgress(100, " ");
    return revealData(data);
  }

  WT.api("info/"+data.files[index].title).success(function(resp) {
    WT.updateProgress(parseInt(((index / data.files.length - 1) + 1) * 100));
    _.extendOwn(data.files[index], resp);
  }).done(function() {
    getInfoOfFiles(data, index + 1);
  });
}

function revealData(data) {
  data.file_count = data.files.length;
  data.plural = data.files.length !== 1;
  data.project_path = WT.projectPath;

  if(data.listType === "unused") {
    data.files = _.filter(data.files, function(file) {
      return file.links.length === 0;
    });
    data.unused_count = data.files.length;
    data.unused_plural = data.unused_count !== 1;
  }

  $(".files").append(
    filesTemplate(data)
  );

  _.each(data.files, function(file, index) {
    file.index = index;
    file.show_links = data.listType !== "unused";
    $(".sound-list").append(fileTemplate(file));
  });

  $(".sound-list-file").on("click", ".action-link", function(e) {
    var $entry = $(e.target).parents(".sound-list-file"),
      index = $entry.data("index"),
      fileData = data.files[index],
      action = e.target.dataset.action,
      promise = $.Deferred();

    if(action === "backlinks") {
      promise = WT.api("backlinks/"+fileData.title);
    } else if(!fileData.source) {
      promise = WT.api("info/"+fileData.title);
    } else {
      promise.resolve(fileData);
    }

    $entry.find("[data-action="+action+"]").addClass("disabled");

    promise.then(function(resp) {
      _.extend(data.files[index], resp);
      $entry.find("."+action).html(fileProps[action](resp));
    });
  });

  $(".loading").hide();
  $("form").addClass("hide");
  $(".output").show();
}

function startOver() {
  $(".output").hide();
  $(".loading").hide();
  $(".result-block").html("");
  $("input[type=checkbox]").prop("checked", false);
  $("input[type=text]").val("");
  $("#composer").val("");
  $("form").removeClass("busy hide");
  history.pushState({}, "Sound Search from MusikAnimal", WT.path);
}
