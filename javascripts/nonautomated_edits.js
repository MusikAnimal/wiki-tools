var Handlebars = require("handlebars");
var contrib = require("../views/nonautomated_edits/contrib.handlebars");
var summary = require("../views/nonautomated_edits/summary.handlebars");
var tool = require("../views/nonautomated_edits/tool.handlebars");

// TODO: make popstate do something
var toolsArray = [], userData = {};

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

  var username = this.username.value;
  this.username.value = (username.charAt(0).toUpperCase() + username.slice(1));

  if(userData.contribs) {
    // moving page to page within contribs
    $("#contribs")[0].scrollIntoView();
  }

  history.pushState({}, username + " - Nonautomated Counter from MusikAnimal", WT.path + "?" + this.params);

  if(this.tools.checked && !toolsArray.length) {
    updateProgress(0);
  }

  WT.api("", this.params).success(
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
  updateProgress(null);
  $(".output").hide();
  $(".loading").hide();
  $(".result-block").html("").hide();
  $(".prev-page, .next-page").hide();
  $("input[type=checkbox]").prop("checked", false);
  $("input[type=text]").val("");
  $("#offset").val(0);
  $("#username").val("");
  $("#namespace").val("");
  $("#dropdown_select").text("All"); // TODO: we can do better than this
  $("form").removeClass("busy hide");
  userData = {};
  history.pushState({}, "Nonautomated Counter from MusikAnimal", WT.path);
}

function countTools(params) {
  if(!toolsArray.length) {
    WT.api("tools").done(function(resp) {
      toolsArray = resp;
    }).then(function() {
      return countTools(params);
    });
  } else {
    countTool(0, params, {});
  }
}

function countTool(id, params, data) {
  if(id === toolsArray.length) {
    updateProgress(100);
    userData.toolCounts = data;
    return showToolCounts(data);
  }

  WT.api("tools/"+id, {
    username: params.username,
    namespace: params.namespace
  }).success(function(resp) {
    updateProgress(parseInt(((id / toolsArray.length - 1) + 1) * 100));
    data[resp.tool_name] = resp.count;
  }).error(function(resp) {
    data[resp.tool_name] = "API failure!";
  }).done(function() {
    countTool(id + 1, params, data);
  });
}

function showData(data) {
  if($.isEmptyObject(userData)) {
    userData = data;
    showTotalCount(userData);
  }

  if(this.contribs.checked && !data.error) {
    showContribs(data);
  }

  if(this.tools.checked && !userData.toolCounts) {
    countTools(data);
  } else {
    // tool counter will do this when it is finished
    revealResults();
  }
}

function showContribs(data) {
  $(".contribs-output").html("").removeClass("busy").show();
  insertContribs(data);
}

function showTotalCount(data) {
  data.namespace_text = data.namespace_text ? data.namespace_text.toLowerCase() : "";
  data.namespace_str = data.namespace_text ? "in the <b>" + data.namespace_text + "</b> namespace" : "total";
  if(!data.automated_count) data.automated_count = data.total_count - data.nonautomated_count;
  data.automated_percentage = Math.round((data.automated_count / data.total_count) * 100);
  data.nonautomated_percentage = Math.round((data.nonautomated_count / data.total_count) * 100);
  data.project_path = WT.projectPath;
  $(".summary-output").html(
    summary(data)
  ).show();
}

function showToolCounts(data) {
  $(".counts-output").show();

  var index = 0;
  var newData = {};

  $.each(data, function(key, val) {
    newData[key] = {
      name: key,
      count: val,
      link: toolsArray[index++].link,
      project_path: WT.projectPath
    };
  });

  var keysSorted = Object.keys(newData).sort(function(a,b) {
    return data[a] - data[b];
  });

  var hasEmpty = false;
  userData.automated_count = 0;

  keysSorted.reverse().forEach(function(key) {
    var props = newData[key];
    if(props.count === 0) {
      hasEmpty = true;
      props.class = "empty";
    } else {
      userData.automated_count += props.count;
    }

    $(".counts-output").append(
      tool(props)
    );
  });

  if(newData["Admin actions"] && newData["Admin actions"].count > 0) {
    $(".notes-output").append(
      "<small>Note: Admin actions count represents only actions for which an edit exists, such as page protections</small>"
    ).show();
  }

  revealResults();
}

function revealResults() {
  updateProgress(null);
  $(".loading").hide();
  $("form").addClass("hide");
  $(".output").show();
}

function insertContribs(resp) {
  $.each(resp.contribs, function(index, contribData) {
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

    if(contribData.page_namespace) {
      contribData.namespace_text = $("li[data-id="+contribData.page_namespace+"]").text().trim()+":";
    }

    $(".contribs-output").append(
      contrib(contribData)
    );
  });

  if(parseInt($("[name=offset]").val()) === 0) {
    $(".prev-page").hide();
  } else {
    $(".prev-page").show();
  }

  if(resp.contribs.length < 50) {
    $(".next-page").hide();
  } else {
    $(".next-page").show();
  }
}

function updateProgress(value) {
  if(value !== null) {
    if(value >= 100) {
      $("progress").val(100);
      $(".progress-report").text("Complete!");
    } else {
      $("progress").val(value).show();
      $(".progress-report").text(value + "%");
    }
  } else {
    $("progress").val(0).hide();
    $(".progress-report").text("");
  }
}
