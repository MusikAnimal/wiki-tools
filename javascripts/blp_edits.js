var Handlebars = require("handlebars");
var contrib = require("../views/blp_edits/contrib.handlebars");
var summary = require("../views/blp_edits/summary.handlebars");

var userData = {};

WT.listeners = function() {
  $(".another-query").on("click", startOver);

  $(".next-page").on("click", function() {
    $("#offset").val(parseInt($("#offset").val()) + 50);
    $(".prev-page, .next-page").hide();
    $(".contribs-output").addClass("busy");
    $("form").trigger("submit");
  });

  $(".prev-page").on("click", function() {
    $("#offset").val(parseInt($("#offset").val()) - 50);
    $(".prev-page, .next-page").hide();
    $(".contribs-output").addClass("busy");
    $("form").trigger("submit");
  });
};

WT.formSubmit = function(e) {
  if(!this.username.value) {
    return alert('Username is required!');
  }

  $("#username").blur();

  var username = this.username.value.charAt(0).toUpperCase() + this.username.value.slice(1);
  this.username.value = username;
  this.params.username = username;

  if(userData.contribs) {
    // moving page to page within contribs
    $("#contribs")[0].scrollIntoView();
  }

  history.pushState({}, username + " - BLP Edit Counter from MusikAnimal", WT.path + "?" + this.params);

  WT.api("", $(this).serialize()).success(
    showData.bind(this)
  ).error(function(resp) {
    if(resp.status === 501) {
      var json = resp.responseJSON;

      $(".contribs-output").html(
        "<p class='error'>" + json.error + "</p>"
      ).show();

      showData.call(this, json);
    } else {
      alert("Something went wrong. Sorry.");
      startOver();
    }
  }.bind(this));
};

function startOver() {
  $(".output").hide();
  $(".loading").hide();
  $(".result-block").html("").hide();
  $(".prev-page, .next-page").hide();
  $("input[type=checkbox]").prop("checked", false);
  $("input[type=text]").val("");
  $("#offset").val(0);
  $("#username").val("");
  $("form").removeClass("busy hide");
  userData = {};
  history.pushState({}, "BLP Edit Counter from MusikAnimal", WT.path);
}

function showData(data) {
  if($.isEmptyObject(userData)) {
    userData = data;
    showTotalCount(userData);
  }

  if(this.contribs.checked && !data.error) {
    showContribs(data);
  }

  revealResults();
}

function showContribs(data) {
  $(".contribs-output").html("").removeClass("busy").show();
  insertContribs(data);
}

function showTotalCount(data) {
  data.project_path = WT.projectPath;
  data.blp_percentage = data.blp_count / data.total_count;

  if(data.nonautomated_blp_count) {
    data.nonautomated = true;
    data.nonautomated_blp_percentage = data.nonautomated_blp_count / data.total_count;
  }

  _.each(["blp_percentage", "nonautomated_blp_percentage"], function(attr) {
    if(data[attr] && data[attr] > 0 && data[attr] < 0.01) {
      data[attr] = "< 1";
    } else {
      data[attr] = Math.round(data[attr] * 100);
    }
  });

  $(".summary-output").html(
    summary(data)
  ).show();
}

function revealResults() {
  // WT.updateProgress(null);
  $(".loading").hide();
  $("form").addClass("hide");
  $(".output").show();
}

function insertContribs(resp) {
  var contribs = resp.contribs || resp.nonautomated_contribs;

  $.each(contribs, function(index, contribData) {
    var year = contribData.rev_timestamp.substr(0, 4),
      month = contribData.rev_timestamp.substr(4, 2),
      day = contribData.rev_timestamp.substr(6, 2),
      hour = contribData.rev_timestamp.substr(8, 2),
      minute = contribData.rev_timestamp.substr(10, 2),
      monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];

    contribData.project_path = WT.projectPath;
    contribData.datestamp = hour + ":" + minute + ", " + day + " " + monthNames[parseInt(month) - 1] + " " + year;
    contribData.minor_edit = !!contribData.rev_minor_edit;
    contribData.humanized_page_title = contribData.page_title.replace(/_/g, " ");
    contribData.summary = WT.wikifyText(contribData.rev_comment, contribData.page_title);

    $(".contribs-output").append(
      contrib(contribData)
    );
  });

  if(parseInt($("[name=offset]").val()) === 0) {
    $(".prev-page").hide();
  } else {
    $(".prev-page").show();
  }

  if(contribs.length < 50) {
    $(".next-page").hide();
  } else {
    $(".next-page").show();
  }
}
