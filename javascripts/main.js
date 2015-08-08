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

    $("form").submit(function(e) {
      e.preventDefault();

      var path = document.location.pathname.split("/").pop(),
        params = $(this).serialize();

      history.pushState({}, $("form[name=username]").val() + " - Nonautomated Counter from MusikAnimal", path + "?" + params);

      $(this).addClass("busy");
      $(".output").html("<p>Thinking...</p>");
      $.ajax({
        url: "/nonautomated_edits",
        method: "POST",
        data: params
      }).success(function(resp) {
        $(this).addClass("hide");
        $(".output").html(
          resp.username + " has <b>" + resp.count + " edits</b> in the " + resp.namespaceText + " namespace"
        );

        if(resp.contribs) {
          $(".output").append("<ul>");
          $.each(resp.contribs, function(index, contribData) {
            var year = contribData.rev_timestamp.substr(0, 4),
              month = contribData.rev_timestamp.substr(4, 2),
              day = contribData.rev_timestamp.substr(6, 2),
              hour = contribData.rev_timestamp.substr(8, 2),
              minute = contribData.rev_timestamp.substr(10, 2),
                monthNames = ["January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
              ];

            $(".output ul").append(
              Handlebars.templates.contrib(contribData)
            );
          });
        }
      }.bind(this)).error(function(resp) {
        alert("Something went wrong. Sorry.");
      });
    });

    // accessibility hacks
    // $(".checkbox").on("keydown", function(e) {
    //   if(e.which === 13) {
    //     $(this).find("label").trigger("click");
    //   }
    // });
  });
})();