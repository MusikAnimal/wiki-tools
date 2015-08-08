(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['contrib'] = template({"compiler":[6,">= 2.0.0-beta.1"],"main":function(depth0,helpers,partials,data) {
  var helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression;
  return "<li>\n  (<a href=\"https://en.wikipedia.org/wiki/Special:Diff/"
    + escapeExpression(((helper = (helper = helpers.rev_id || (depth0 != null ? depth0.rev_id : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"rev_id","hash":{},"data":data}) : helper)))
    + "\">diff</a> | hist)\n  "
    + escapeExpression(((helper = (helper = helpers.rev_timestamp || (depth0 != null ? depth0.rev_timestamp : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"rev_timestamp","hash":{},"data":data}) : helper)))
    + "\n  <i>"
    + escapeExpression(((helper = (helper = helpers.rev_comment || (depth0 != null ? depth0.rev_comment : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"rev_comment","hash":{},"data":data}) : helper)))
    + "</i>\n</li>";
},"useData":true});
})();