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
  data.policy_percentage = data.policy_count / data.total_count;
  data.guideline_percentage = data.guideline_count / data.total_count;

  if(data.nonautomated_policy_count) {
    data.nonautomated = true;
    data.nonautomated_policy_percentage = data.nonautomated_policy_count / data.total_count;
    data.nonautomated_guideline_percentage = data.nonautomated_guideline_count / data.total_count;
    data.pg_count = data.nonautomated_policy_count + data.nonautomated_guideline_count;
  }

  _.each(["policy_percentage", "nonautomated_policy_percentage", "guideline_percentage", "nonautomated_guideline_percentage"], function(attr) {
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

