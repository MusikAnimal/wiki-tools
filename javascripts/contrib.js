(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['contrib'] = template({"1":function(depth0,helpers,partials,data) {
  return "<span class=\"minor-edit\">m</span>";
  },"compiler":[6,">= 2.0.0-beta.1"],"main":function(depth0,helpers,partials,data) {
  var stack1, helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression, buffer = "<li>\n  <a href=\""
    + escapeExpression(((helper = (helper = helpers.project_path || (depth0 != null ? depth0.project_path : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"project_path","hash":{},"data":data}) : helper)))
    + "/wiki/Special:PermaLink/"
    + escapeExpression(((helper = (helper = helpers.rev_id || (depth0 != null ? depth0.rev_id : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"rev_id","hash":{},"data":data}) : helper)))
    + "\">"
    + escapeExpression(((helper = (helper = helpers.datestamp || (depth0 != null ? depth0.datestamp : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"datestamp","hash":{},"data":data}) : helper)))
    + "</a>\n  (<a href=\""
    + escapeExpression(((helper = (helper = helpers.project_path || (depth0 != null ? depth0.project_path : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"project_path","hash":{},"data":data}) : helper)))
    + "/wiki/Special:Diff/"
    + escapeExpression(((helper = (helper = helpers.rev_id || (depth0 != null ? depth0.rev_id : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"rev_id","hash":{},"data":data}) : helper)))
    + "\">diff</a> | <a href=\""
    + escapeExpression(((helper = (helper = helpers.project_path || (depth0 != null ? depth0.project_path : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"project_path","hash":{},"data":data}) : helper)))
    + "/w/index.php?title="
    + escapeExpression(((helper = (helper = helpers.page_title || (depth0 != null ? depth0.page_title : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"page_title","hash":{},"data":data}) : helper)))
    + "&action=history\">hist</a>)\n  . .\n  ";
  stack1 = helpers['if'].call(depth0, (depth0 != null ? depth0.minor_edit : depth0), {"name":"if","hash":{},"fn":this.program(1, data),"inverse":this.noop,"data":data});
  if (stack1 != null) { buffer += stack1; }
  buffer += "\n  <a href=\""
    + escapeExpression(((helper = (helper = helpers.project_path || (depth0 != null ? depth0.project_path : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"project_path","hash":{},"data":data}) : helper)))
    + "/wiki/"
    + escapeExpression(((helper = (helper = helpers.page_title || (depth0 != null ? depth0.page_title : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"page_title","hash":{},"data":data}) : helper)))
    + "\">"
    + escapeExpression(((helper = (helper = helpers.humanized_page_title || (depth0 != null ? depth0.humanized_page_title : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"humanized_page_title","hash":{},"data":data}) : helper)))
    + "</a>\n  <i>(";
  stack1 = ((helper = (helper = helpers.summary || (depth0 != null ? depth0.summary : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"summary","hash":{},"data":data}) : helper));
  if (stack1 != null) { buffer += stack1; }
  return buffer + ")</i>\n</li>";
},"useData":true});
})();