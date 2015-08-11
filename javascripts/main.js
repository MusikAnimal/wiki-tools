(function() {
  $(document).ready(function() {
    if(document.location.search.indexOf("username=") !== -1) {
      debugger;
      // $("form").trigger("submit");
    }

    $("#dropdown_select").on("click", function() {
      $(".namespace-selector").addClass("open");

      setTimeout(function() {
        $(document).one("click.dropdown", function() {
          $(".namespace-selector").removeClass("open");
        });
      }, 0);
    });

    $(".dropdown li").on("click", function() {
      $("#namespace").val($(this).data("id"));
      $("#dropdown_select").text($(this).text());
    });

    var path = document.location.pathname.split("/").pop();

    $("form").submit(function(e) {
      e.preventDefault();

      var params = $(this).serialize();

      history.pushState({}, $("form[name=username]").val() + " - Nonautomated Counter from MusikAnimal", path + "?" + params);

      $(this).addClass("busy");
      $(".contribs-output").html("<p>Thinking...</p>");
      $.ajax({
        url: "/api/nonautomated_edits",
        method: "GET",
        data: params,
        dataType: "JSON"
      }).success(function(resp) {
        $(this).addClass("hide");
        showTotalCount(resp);

        if(resp.contribs) {
          insertContribs(resp);
        } else {
          $(".contribs-output").html("");
        }

        $(".another-query").show();
      }.bind(this)).error(function(resp) {
        if(resp.status === 501) {
          var json = resp.responseJSON;

          $(this).addClass("hide");
          showTotalCount(json);

          $(".contribs-output").html(
            "<p class='error'>" + json.error + "</p>"
          );
          $(".another-query").show();
        } else {
          alert("Something went wrong. Sorry.");
          $(".contribs-output").html("");
        }
        $(this).removeClass("busy");
      }.bind(this));
    });

    $(".another-query").on("click", function() {
      $(".another-query").hide();
      $(".total-output").html("");
      $(".contribs-output").html("");
      $(".prev-page, .next-page").hide();
      $("form").removeClass("hide").removeClass("busy")[0].reset();
      history.pushState({}, "Nonautomated Counter from MusikAnimal", path);
    });

    $(".next-page").on("click", function() {
      $("#offset").val(parseInt($("#offset").val()) + 50);
      $(".prev-page, .next-page").hide();
      $("form").trigger("submit");
    });

    $(".prev-page").on("click", function() {
      $("#offset").val(parseInt($("#offset").val()) - 50);
      $(".prev-page, .next-page").hide();
      $("form").trigger("submit");
    });

    // accessibility hacks
    // $(".checkbox").on("keydown", function(e) {
    //   if(e.which === 13) {
    //     $(this).find("label").trigger("click");
    //   }
    // });
  });

  function showTotalCount(resp) {
    $(".total-output").html(
      resp.username + " has approximately <b>" + resp.count + " non-automated edits</b> in the " + resp.namespaceText + " namespace"
    );
  }

  function insertContribs(resp) {
    $(".contribs-output").html("<ul>");

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

      $(".contribs-output ul").append(
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
