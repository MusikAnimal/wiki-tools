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
      $(this).addClass("busy");
      $("main").append("<p>Thinking...</p>");
      $.ajax({
        url: "/nonautomated_edits",
        method: "POST",
        data: $(this).serialize()
      }).done(function(resp) {
        debugger;
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