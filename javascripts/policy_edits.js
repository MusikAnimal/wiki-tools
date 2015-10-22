var Handlebars = require("handlebars");
var summary = require("../views/policy_edits/summary.handlebars");

var Revisions = new Contribs({
  appName: "Policies and Guidelines Edit Counter",
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
  data.pg_count = data.policy_count + data.guideline_count;
  data.policy_percentage = Revisions.getPercentage(data.policy_count, data.total_count);
  data.guideline_percentage = Revisions.getPercentage(data.guideline_count, data.total_count);

  if(typeof data.nonautomated_policy_count === 'number') {
    data.nonautomated = true;
    data.nonautomated_policy_percentage = Revisions.getPercentage(data.nonautomated_policy_count, data.total_count);
    data.nonautomated_guideline_percentage = Revisions.getPercentage(data.nonautomated_guideline_count, data.total_count);
    data.pg_count = data.nonautomated_policy_count + data.nonautomated_guideline_count;
  }

  $(".summary-output").html(
    summary(data)
  ).show();
}
