$(function () {
  var counter = setInterval(function() {
    var count = parseInt($('.redirect-countdown').text(), 10) - 1;
    $('.redirect-countdown').html(count);

    if (count === 0) {
      clearInterval(counter);
      $('.countdown-text').html('XTools is now loading...');
      var username = $('#username').val() ? '/' + $('#username').val() : '';
      var namespace = $("#namespace").val().length > 0 ? '/' + $("#namespace").val() : '';
      return document.location = 'https://xtools.wmflabs.org/autoedits/en.wikipedia.org' + username + namespace;
    }
  }, 1000);
});
