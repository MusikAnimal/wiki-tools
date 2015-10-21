var Handlebars = require("handlebars");
var summary = require("../views/blp_edits/summary.handlebars");

var Revisions = new Contribs({
  appName: "BLP Edit Counter",
  showData: showData
});

function showData(data) {
  if($.isEmptyObject(Revisions.userData)) {
    Revisions.userData = data;
    showTotalCount(Revisions.userData);
  }

  if(this.contribs.checked && !data.error) {
    Revisions.showContribs(data);
  }

  Revisions.revealResults();
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
