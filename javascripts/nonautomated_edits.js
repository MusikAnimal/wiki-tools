var Handlebars = require("handlebars");
var summary = require("../views/nonautomated_edits/summary.handlebars");
var tool = require("../views/nonautomated_edits/tool.handlebars");

// TODO: make popstate do something
var toolsArray = [];

var Revisions = new Contribs({
  appName: "Nonautomated Edit Counter",
  preSubmit: function() {
    if(this.tools.checked && !toolsArray.length) {
      WT.updateProgress(0);
    }
  },
  showData: showData
});

function startOver() {
  Revisions.startOver();
  $("input[type=checkbox]").prop("checked", false);
  $("#namespace").val("");
  $("#dropdown_select").text("All"); // TODO: we can do better than this
  WT.updateProgress(null);
  history.pushState({}, "Nonautomated Edit Counter from MusikAnimal", WT.path);
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
    WT.updateProgress(100);
    Revisions.userData.toolCounts = data;
    return showToolCounts(data);
  }

  WT.api("tools/"+id, {
    username: params.username,
    namespace: params.namespace
  }).success(function(resp) {
    WT.updateProgress(parseInt(((id / toolsArray.length - 1) + 1) * 100));
    data[resp.tool_name] = resp.count;
  }).error(function(resp) {
    data[resp.tool_name] = "API failure!";
  }).done(function() {
    countTool(id + 1, params, data);
  });
}

function showData(data) {
  if($.isEmptyObject(Revisions.userData)) {
    Revisions.userData = data;
    showTotalCount(Revisions.userData);
  }

  if(this.contribs.checked && !data.error) {
    Revisions.showContribs(data);
  }

  if(this.tools.checked && !Revisions.userData.toolCounts) {
    countTools(data);
  } else {
    // tool counter will do this when it is finished
    Revisions.revealResults();
  }
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
  Revisions.userData.automated_count = 0;

  keysSorted.reverse().forEach(function(key) {
    var props = newData[key];
    if(props.count === 0) {
      hasEmpty = true;
      props.class = "empty";
    } else {
      Revisions.userData.automated_count += props.count;
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

  Revisions.revealResults();
}
