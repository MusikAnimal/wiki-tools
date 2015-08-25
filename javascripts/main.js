// TODO: make popstate do something
(function() {
  var toolsArray = [], userData = {};
  var path = document.location.pathname.split("/").pop();
  var projectPath = "https://en.wikipedia.org"

  $(document).ready(function() {
    if(document.location.search.indexOf("username=") !== -1) {
      setTimeout(function() {
        $("form").trigger("submit");
      });
    }

    $("#dropdown_select").on("click", function(e) {
      if($(".namespace-selector").hasClass("open")) {
        return;
      }
      $(".namespace-selector").addClass("open");
      e.stopPropagation();

      setTimeout(function() {
        $(document).one("click.dropdown", function(e) {
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

      if(!this.username.value) {
        return alert('Username is required!');
      }

      $("button").blur();
      $(".loading").show();
      $(this).addClass("busy");

      var username = this.username.value;
      this.username.value = (username.charAt(0).toUpperCase() + username.slice(1));

      if(this.tools.checked && !toolsArray.length) {
        updateProgress(0);
      }

      if(userData.contribs) {
        // moving page to page within contribs
        $("#contribs")[0].scrollIntoView();
      }

      var params = $(this).serialize();
      history.pushState({}, $("form[name=username]").val() + " - Nonautomated Counter from MusikAnimal", path + "?" + params);

      $.ajax({
        url: "/musikanimal/api/nonautomated_edits",
        method: "GET",
        data: params,
        dataType: "JSON"
      }).success(
        showData.bind(this)
      ).error(function(resp) {
        if(resp.status === 501) {
          var json = resp.responseJSON;

          $(".contribs-output").html(
            "<p class='error'>" + json.error + "</p>"
          ).show();

          showData.call(this, json);
        } else {
          alert("Something went wrong. Sorry.");
          startOver();
        }
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

    $(".expander").on("click", function() {
      $(this).toggleClass("expanded");
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
    $(".output").hide();
    $(".loading").hide();
    $(".result-block").html("").hide();
    $(".prev-page, .next-page").hide();
    $("input[type=checkbox]").prop("checked", false);
    $("input[type=text]").val("");
    $("#offset").val(0);
    $("#username").val("");
    $("#namespace").val("");
    $("#dropdown_select").text("All"); // TODO: we can do better than this
    $("form").removeClass("busy hide");
    userData = {}
    history.pushState({}, "Nonautomated Counter from MusikAnimal", path);
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
      userData.toolCounts = data;
      return showToolCounts(data);
    }

    api("tools/"+id, {
      username: params.username,
      namespace: params.namespace
    }).success(function(resp) {
      updateProgress(parseInt(((id / toolsArray.length - 1) + 1) * 100));
      data[resp.tool_name] = resp.nonautomated_count;
    }).error(function(resp) {
      data[resp.tool_name] = "API failure!";
    }).done(function() {
      countTool(id + 1, params, data);
    });
  }

  function api(endpoint, params) {
    return $.ajax({
      url: "/musikanimal/api/nonautomated_edits/"+endpoint,
      method: "GET",
      data: params,
      dataType: "JSON"
    })
  }

  function showData(data) {
    if($.isEmptyObject(userData)) {
      userData = data;
      showTotalCount(data);
    }

    if(this.contribs.checked && !data.error) {
      showContribs(data);
    }

    if(this.tools.checked &&  !userData.toolCounts) {
      countTools(data);
    } else {
      // tool counter will do this when it is finished
      revealResults();
    }
  }

  function showContribs(data) {
    $(".contribs-output").html("").removeClass("busy").show();
    insertContribs(data);
  }

  function showTotalCount(data) {
    data.namespace_str = data.namespace_text ? "in the <b>" + data.namespace_text.toLowerCase() + "</b> namespace" : "total";
    data.automated_count = data.total_count - data.nonautomated_count
    data.automated_percentage = Math.round((data.automated_count / data.total_count) * 100)
    data.nonautomated_percentage = Math.round((data.nonautomated_count / data.total_count) * 100)
    data.project_path = projectPath
    $(".summary-output").html(
      Handlebars.templates.summary(data)
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
        project_path: projectPath
      }
    });

    var keysSorted = Object.keys(newData).sort(function(a,b) {
      return data[a] - data[b];
    });

    var hasEmpty = false;

    keysSorted.reverse().forEach(function(key) {
      var props = newData[key];
      if(props.count === 0) {
        hasEmpty = true;
        props.class = "empty";
      }

      $(".counts-output").append(
        Handlebars.templates.tool(props)
      );
    });

    if(keysSorted.indexOf("Admin actions")) {
      $(".notes-output").append(
        "<small>Note: Admin actions count represents only actions for which an edit exists, such as page protections</small>"
      ).show();
    }

    revealResults();
  }

  function revealResults() {
    updateProgress(null);
    $(".loading").hide();
    $("form").addClass("hide");
    $(".output").show();
  }

  function insertContribs(resp) {
    $.each(resp.contribs, function(index, contribData) {
      var year = contribData.rev_timestamp.substr(0, 4),
        month = contribData.rev_timestamp.substr(4, 2),
        day = contribData.rev_timestamp.substr(6, 2),
        hour = contribData.rev_timestamp.substr(8, 2),
        minute = contribData.rev_timestamp.substr(10, 2),
        monthNames = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
        ];

      contribData.project_path = projectPath;
      contribData.datestamp = hour + ":" + minute + ", " + day + " " + monthNames[parseInt(month) - 1] + " " + year;
      contribData.minor_edit = !!contribData.rev_minor_edit;
      contribData.humanized_page_title = contribData.page_title.replace(/_/g, " ");
      contribData.summary = wikifyText(contribData.rev_comment, contribData.page_title);

      if(contribData.page_namespace) {
        contribData.namespace_text = $("li[data-id="+contribData.page_namespace+"]").text().trim()+":";
      }

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
        $("progress").val(value).show();
        $(".progress-report").text(value + "%");
      }
    } else {
      $("progress").val(0).hide();
      $(".progress-report").text("");
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
