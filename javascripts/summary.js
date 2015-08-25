(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['summary'] = template({"1":function(depth0,helpers,partials,data) {
  var helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression;
  return "<p>Totals for the <b>"
    + escapeExpression(((helper = (helper = helpers.namespace_text || (depth0 != null ? depth0.namespace_text : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"namespace_text","hash":{},"data":data}) : helper)))
    + "</b> namespace:</p>";
},"3":function(depth0,helpers,partials,data) {
  var helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression;
  return " ("
    + escapeExpression(((helper = (helper = helpers.automated_percentage || (depth0 != null ? depth0.automated_percentage : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"automated_percentage","hash":{},"data":data}) : helper)))
    + "%)";
},"5":function(depth0,helpers,partials,data) {
  var helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression;
  return " ("
    + escapeExpression(((helper = (helper = helpers.nonautomated_percentage || (depth0 != null ? depth0.nonautomated_percentage : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"nonautomated_percentage","hash":{},"data":data}) : helper)))
    + "%)";
},"compiler":[6,">= 2.0.0-beta.1"],"main":function(depth0,helpers,partials,data) {
  var stack1, helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression, buffer = "<a href=\""
    + escapeExpression(((helper = (helper = helpers.project_path || (depth0 != null ? depth0.project_path : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"project_path","hash":{},"data":data}) : helper)))
    + "/wiki/User:"
    + escapeExpression(((helper = (helper = helpers.username || (depth0 != null ? depth0.username : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"username","hash":{},"data":data}) : helper)))
    + "\">"
    + escapeExpression(((helper = (helper = helpers.username || (depth0 != null ? depth0.username : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"username","hash":{},"data":data}) : helper)))
    + "</a> has approximently <b>"
    + escapeExpression(((helper = (helper = helpers.nonautomated_count || (depth0 != null ? depth0.nonautomated_count : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"nonautomated_count","hash":{},"data":data}) : helper)))
    + "</b> non-automated edits ";
  stack1 = ((helper = (helper = helpers.namespace_str || (depth0 != null ? depth0.namespace_str : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"namespace_str","hash":{},"data":data}) : helper));
  if (stack1 != null) { buffer += stack1; }
  buffer += "\n\n";
  stack1 = helpers['if'].call(depth0, (depth0 != null ? depth0.namespace_text : depth0), {"name":"if","hash":{},"fn":this.program(1, data),"inverse":this.noop,"data":data});
  if (stack1 != null) { buffer += stack1; }
  buffer += "\n\n<dl>\n  <dt>Total edits</dt><dd>"
    + escapeExpression(((helper = (helper = helpers.total_count || (depth0 != null ? depth0.total_count : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"total_count","hash":{},"data":data}) : helper)))
    + "</dd>\n  <dt>Automated edits</dt><dd>"
    + escapeExpression(((helper = (helper = helpers.automated_count || (depth0 != null ? depth0.automated_count : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"automated_count","hash":{},"data":data}) : helper)));
  stack1 = helpers['if'].call(depth0, (depth0 != null ? depth0.automated_percentage : depth0), {"name":"if","hash":{},"fn":this.program(3, data),"inverse":this.noop,"data":data});
  if (stack1 != null) { buffer += stack1; }
  buffer += "</dd>\n  <dt>Non-automated edits</dt><dd>"
    + escapeExpression(((helper = (helper = helpers.nonautomated_count || (depth0 != null ? depth0.nonautomated_count : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"nonautomated_count","hash":{},"data":data}) : helper)));
  stack1 = helpers['if'].call(depth0, (depth0 != null ? depth0.nonautomated_percentage : depth0), {"name":"if","hash":{},"fn":this.program(5, data),"inverse":this.noop,"data":data});
  if (stack1 != null) { buffer += stack1; }
  return buffer + "</dd>\n</dl>\n\n<small>Note: Edit counts do not include those of deleted pages. All data is approximate.</small>";
},"useData":true});
})();