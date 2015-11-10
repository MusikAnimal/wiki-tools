var Handlebars = require("handlebars");
var category_entry = require("../views/category_edits/category.handlebars");
var summary = require("../views/category_edits/summary.handlebars");
var elapsedTime;

var Revisions = new Contribs({
  appName: "Category Edit Counter",
  preSubmit: function() {
    if(this.totals.checked && !Revisions.userData.categoryData) {
      WT.updateProgress(0);
    }
  },
  showData: showData
});

function startOver() {
  Revisions.startOver();
  $("input[type=checkbox]").prop("checked", false);
  WT.updateProgress(null);
  history.pushState({}, "Category Edit Counter from MusikAnimal", WT.path);
}

function countCategory(i, data, categoryData) {
  if(i === data.categories.length) {
    WT.updateProgress(100);
    Revisions.userData.categoryData = categoryData;
    return showCategoryCounts(categoryData);
  }

  WT.updateProgress(parseInt(((i + 1) / (data.categories.length + 1)) * 100));

  WT.api("category/"+data.categories[i], {
    username: data.username,
    nonautomated: !!data.nonautomated ? 'on' : '',
    noreplag: true
  }).success(function(resp) {
    var count = resp.count || resp.nonautomated_count || 0,
      percentage = Revisions.getPercentage(count, data.total_count);
    categoryData.push({
      name: resp.category_name,
      humanized_name: data.categories[i].replace(/_/g, ' '),
      count: count,
      percentage: percentage
    });
  }).error(function(resp) {
    categoryData.push({
      name: data.categories[i],
      humanized_name: data.categories[i].replace(/_/g, ' '),
      count: 'API failure!',
      percentage: null
    });
  }).done(function(resp) {
    elapsedTime += resp.elapsed_time;
    countCategory(i + 1, data, categoryData);
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

  if(this.totals.checked && !Revisions.userData.categoryData) {
    data.nonautomated = this.nonautomated.checked;
    data.total_category_count = data.total_category_count || data.total_nonautomated_category_count || 0;
    elapsedTime = data.elapsed_time;
    countCategory(0, data, []);
  } else {
    Revisions.revealResults();
  }
}

function showTotalCount(data) {
  data.project_path = WT.projectPath;
  data.category_count = data.total_category_count || data.total_nonautomated_category_count || 0;
  data.category_percentage = Revisions.getPercentage(data.category_count, data.total_count);
  data.replication_lag = WT.replag(data.replication_lag);

  if(data.total_nonautomated_category_count) {
    data.nonautomated = true;
  }

  $(".summary-output").html(
    summary(data)
  ).show();
}

function showCategoryCounts(categoryData) {
  _.each(categoryData, function(category) {
    category.project_path = WT.projectPath;
    $(".category-counts").append(category_entry(category));
  });

  $(".elapsed-time").text(+elapsedTime.toFixed(3));

  Revisions.revealResults();
}
