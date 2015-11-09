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
  data.blp_percentage = Revisions.getPercentage(data.blp_count, data.total_count);
  data.replication_lag = WT.replag(data.replication_lag);

  if(data.nonautomated_blp_count) {
    data.nonautomated = true;
    data.nonautomated_blp_percentage = Revisions.getPercentage(data.nonautomated_blp_count, data.total_count);
  }

  $(".summary-output").html(
    summary(data)
  ).show();
}
