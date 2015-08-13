// TODO: make popstate do something
(function() {
  var toolsArray = [], countData;
  var path = document.location.pathname.split("/").pop();

  $(document).ready(function() {
    if(document.location.search.indexOf("username=") !== -1) {
      setTimeout(function() {
        $("form").trigger("submit");
      });
    }

    $("#dropdown_select").on("click", function() {
      $(".namespace-selector").addClass("open");

      setTimeout(function() {
        $(document).one("click.dropdown", function() {
          $(".namespace-selector").removeClass("open");
        });
      });
    });

    $(".dropdown li").on("click", function() {
      $("#namespace").val($(this).data("id"));
      $("#dropdown_select").text($(this).text());
    });

    $("form").submit(function(e) {
      e.preventDefault();
      $("button").blur();
      $(".loading").show();

      var $username = $("[name=username]");
      $username.val($username.val().charAt(0).toUpperCase() + $username.val().slice(1));

      if($("[name=tools]").is(":checked")) {
        if(countData && countData.toolCounts) {
          // already queried for count data
          $("[name=tools]").prop("checked", false);
        } else {
          var toolCount = true;
          updateProgress(0);
        }
      }

      if(countData && countData.contribs) {
        // moving page to page within contribs
        $("#contribs")[0].scrollIntoView();
      }

      var params = $(this).serialize();
      history.pushState({}, $("form[name=username]").val() + " - Nonautomated Counter from MusikAnimal", path + "?" + params);

      $(this).addClass("busy");
      $(".loading-wrapper").show();

      $.ajax({
        url: "/api/nonautomated_edits",
        method: "GET",
        data: params,
        dataType: "JSON"
      }).success(function(resp) {
        countData = resp;

        if(toolCount) {
          countTools(countData);
        } else {
          showResults(countData);
        }
      }.bind(this)).error(function(resp) {
        if(resp.status === 501) {
          var json = resp.responseJSON;

          $(this).addClass("hide");
          showTotalCount(json);

          $(".contribs-output").html(
            "<p class='error'>" + json.error + "</p>"
          ).show();
        } else {
          alert("Something went wrong. Sorry.");
          $(".contribs-output").html("");
        }

        $(this).removeClass("busy");
        if(toolCount) updateProgress(null);
      }.bind(this));
    });

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

    // accessibility hacks
    // $(".checkbox").on("keydown", function(e) {
    //   if(e.which === 13) {
    //     $(this).find("label").trigger("click");
    //   }
    // });
  });

  function startOver() {
    updateProgress(null);
    $(".results").html("");
    $(".output").hide();
    $("form").removeClass("hide").removeClass("busy")[0].reset();
    history.pushState({}, "Nonautomated Counter from MusikAnimal", path);
    countData = undefined;
  }

  function countTools(params) {
    if(!toolsArray.length) {
      api("tools").done(function(resp) {
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
      countData.toolCounts = data;
      return showResults(countData);
    }

    api("tools/"+id, {
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

  function api(endpoint, params) {
    return $.ajax({
      url: "/api/nonautomated_edits/"+endpoint,
      method: "GET",
      data: params,
      dataType: "JSON"
    })
  }

  function showResults(data) {
    updateProgress(null);
    $("form").addClass("hide");
    $(".output").show();
    showTotalCount(data);

    if(data.toolCounts) {
      $(".counts-output").show();
      $.each(data.toolCounts, function(tool, count) {
        $(".counts-output").append(
          "<dt>" + tool + "</dt><dd>" + count + "</dd>"
        );
      });
    } else {
      $(".counts-output").hide();
    }

    if(data.contribs && data.contribs.length) {
      insertContribs(data);
    } else {
      $(".contribs-output").html("").hide();
    }
  }

  function showTotalCount(resp) {
    $(".total-output").html(
      resp.username + " has approximately <b>" + resp.count + " non-automated edits</b> in the " + resp.namespaceText + " namespace"
    );
  }

  function insertContribs(resp) {
    $(".contribs-output").html("").removeClass("busy").show();

    $.each(resp.contribs, function(index, contribData) {
      var year = contribData.rev_timestamp.substr(0, 4),
        month = contribData.rev_timestamp.substr(4, 2),
        day = contribData.rev_timestamp.substr(6, 2),
        hour = contribData.rev_timestamp.substr(8, 2),
        minute = contribData.rev_timestamp.substr(10, 2),
        monthNames = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
        ];

      contribData.project_path = "https://en.wikipedia.org";
      contribData.datestamp = hour + ":" + minute + ", " + day + " " + monthNames[parseInt(month) - 1] + " " + year;
      contribData.minor_edit = !!contribData.rev_minor_edit;
      contribData.humanized_page_title = contribData.page_title.replace(/_/g, " ");
      contribData.summary = wikifyText(contribData.rev_comment, contribData.page_title);

      $(".contribs-output").append(
        Handlebars.templates.contrib(contribData)
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
        $(".loading").show();
        $("progress").val(value).show();
        $(".progress-report").text(value + "%");
      }
    } else {
      $("progress").val(0).hide();
      $(".progress-report").text("");
      $(".loading").hide();
    }
  }

  function wikifyText(text, pageName) {
    var sectionRegex = new RegExp(/^\/\* (.*?) \*\//), sectionMatch;
    if(sectionMatch = sectionRegex.exec(text)) {
      var sectionTitle = sectionMatch[1];
      text = text.replace(sectionMatch[0],
        "<a href='https://en.wikipedia.org/wiki/"+pageName+"#"+sectionTitle.replace(/ /g,"_")+"'>&rarr;</a><span class='gray'>"+sectionTitle+":</span> "
      )
    }

    var linkRegex = new RegExp(/\[\[(.*?)\]\]/g), linkMatch;
    while(linkMatch = linkRegex.exec(text)) {
      var wikilink = linkMatch[1].split("|")[0],
        wikitext = linkMatch[1].split("|")[1] || wikilink,
        link = "<a href='https://en.wikipedia.org/wiki/"+wikilink+"' class='section-link'>"+wikitext+"</a>";

      text = text.replace(linkMatch[0], link);
    }

    return text;
  }
})();
