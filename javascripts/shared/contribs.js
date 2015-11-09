var contrib = require("../../views/nonautomated_edits/contrib.handlebars");

Contribs = function(opts) {
  this.appName = opts.appName;
  this.preSubmit = opts.preSubmit;
  this.showData = opts.showData;

  var self = this;

  this.getPercentage = function(count, total) {
    count = count || 0;
    var quotient = (count / total) || 0;

    if(quotient > 0 && quotient < 0.01) {
      percentage = "< 1";
    } else {
      percentage = Math.round(quotient * 100);
    }

    return percentage + '%';
  };

  this.revealResults = function() {
    WT.updateProgress(null);
    $(".loading").hide();
    $("form").addClass("hide");
    $(".output").show();
  };

  this.showContribs = function(data) {
    data.contribs = data.contribs || data.nonautomated_contribs;
    $(".contribs-output").html("").removeClass("busy").show();
    $.each(data.contribs, function(index, contribData) {
      var year = contribData.rev_timestamp.substr(0, 4),
        month = contribData.rev_timestamp.substr(4, 2),
        day = contribData.rev_timestamp.substr(6, 2),
        hour = contribData.rev_timestamp.substr(8, 2),
        minute = contribData.rev_timestamp.substr(10, 2),
        monthNames = ["January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
        ];

      contribData.project_path = WT.projectPath;
      contribData.datestamp = hour + ":" + minute + ", " + day + " " + monthNames[parseInt(month) - 1] + " " + year;
      contribData.minor_edit = !!contribData.rev_minor_edit;
      contribData.humanized_page_title = contribData.page_title.replace(/_/g, " ");
      contribData.summary = WT.wikifyText(contribData.rev_comment, contribData.page_title);

      if(contribData.page_namespace) {
        contribData.namespace_text = $("li[data-id="+contribData.page_namespace+"]").text().trim()+":";
      }

      $(".contribs-output").append(
        contrib(contribData)
      );
    });

    if(parseInt($("[name=offset]").val()) === 0) {
      $(".prev-page").hide();
    } else {
      $(".prev-page").show();
    }

    if(data.contribs.length < 50) {
      $(".next-page").hide();
    } else {
      $(".next-page").show();
    }
  };

  this.startOver = function() {
    $(".output").hide();
    $(".loading").hide();
    $(".result-block").html("").hide();
    $(".prev-page, .next-page").hide();
    $("input[type=text]").val("");
    $("#offset").val(0);
    $("form").removeClass("busy hide");
    self.userData = {};
    history.pushState({}, self.appName + " from MusikAnimal", WT.path);
  };

  this.userData = {};

  // WT hooks
  WT.listeners = function() {
    $(".another-query").on("click", self.startOver);

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
  };

  WT.formSubmit = function(e) {
    if(!this.username.value) {
      return alert('Username is required!');
    }

    $("input").blur();

    var username = this.username.value.charAt(0).toUpperCase() + this.username.value.slice(1);
    this.username.value = username;

    if(self.userData.contribs) {
      // moving page to page within contribs
      $("#contribs")[0].scrollIntoView();
    }

    history.pushState({}, username + " - " + self.appName + " from MusikAnimal", WT.path + "?" + $(this).serialize());

    if(typeof self.preSubmit === "function") self.preSubmit.call(this);

    WT.api("", $(this).serialize()).success(
      self.showData.bind(this)
    ).error(function(resp) {
      if(resp.status === 501) {
        var json = resp.responseJSON;

        $(".contribs-output").html(
          "<p class='error'>" + json.error + "</p>"
        ).show();

        self.showData.call(this, json);
      } else if(resp.status === 400) {
        alert(resp.responseJSON.error);
        self.startOver();
      } else {
        alert("Something went wrong. Sorry.");
        self.startOver();
      }
    }.bind(this));
  };
};
