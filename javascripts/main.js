(function() {
  $(document).ready(function() {
    // FIXME: check for `namespace` URL param and set custom dropdown value
    // OR... you could make the text field not hidden but style it like a normal unstyled DIV!

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
      $(".output").html("<p>Thinking...</p>");
      $.ajax({
        url: "/nonautomated_edits",
        method: "POST",
        data: params
      }).success(function(resp) {
        $(this).addClass("hide");
        $(".total-count").html(
          resp.username + " has approximately <b>" + resp.count + " non-automated edits</b> in the " + resp.namespaceText + " namespace"
        );

        if(resp.contribs) {
          insertContribs(resp);
        } else {
          $(".output").html("");
        }

        $(".another-query").show();
      }.bind(this)).error(function(resp) {
        alert("Something went wrong. Sorry.");
        $(".output").html("");
        $(this).removeClass("busy");
      }.bind(this));
    });

    $(".another-query").on("click", function() {
      $(".another-query").hide();
      $(".total-count").html("");
      $(".output").html("");
      $("form").removeClass("hide").removeClass("busy")[0].reset();
      history.pushState({}, "Nonautomated Counter from MusikAnimal", path);
    });

    $(".next-page").on("click", function() {
      $("#offset").val(parseInt($("#offset").val()) + 50);
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

  function insertContribs(resp) {
    $(".output").html("<ul>");

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

      $(".output ul").append(
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
})();