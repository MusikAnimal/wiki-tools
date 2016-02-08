/*
  Pageviews Comparison tool

  Forked by MusikAnimal from https://gist.github.com/marcelrf/49738d14116fd547fe6d courtesy of marcelrf

  Copyright 2016 MusikAnimal
  Redistributed under the MIT License: https://opensource.org/licenses/MIT
*/

var config = {
  // For more information on the list of all Wikimedia languages and projects, see:
  // https://www.mediawiki.org/wiki/Extension:SiteMatrix
  // https://en.wikipedia.org/w/api.php?action=sitematrix&formatversion=2
  colors: ['#bccbda', '#e0ad91', '#c1aa78', '#8da075', '#998a6f', '#F24236', '#F5F749', '#EFBDEB', '#2E86AB', '#565554'],
  projectInput: '.aqs-project-input',
  dateRangeSelector: '.aqs-date-range-selector',
  articleSelector: '.aqs-article-selector',
  chart: '.aqs-chart',
  minDate: moment('2015-10-01'),
  maxDate: moment().subtract(1, 'days'),
  timestampFormat: 'YYYYMMDD00',
  daysAgo: 20
};

var normalized = false;

function getProject() {
  var project = $(config.projectInput).val();
  // Get the first 2 characters from the project code to get the language
  return project.replace(/.org$/, '');
}

function getPageURL(page) {
  return "//" + getProject() + ".org/wiki/" + page;
}

function setupProjectInput() {
  var projectInput = $(config.projectInput);

  projectInput.on('change', function () {
    if(!this.value) {
      this.value = 'en.wikipedia.org';
      return;
    }
    if(validateProject()) return;
    resetArticleSelector(); // This will call updateChart() itself.
  });
}

function validateProject() {
  var project = $(config.projectInput).val();
  if(/^www\./.test(project)) {
    $(config.projectInput).val(project.substring(4));
  } else if(sites.indexOf(project) === -1) {
    writeMessage(
      "<a href='//" + project + "'>" + project + "</a> is not a " +
      "<a href='https://en.wikipedia.org/w/api.php?action=sitematrix&formatversion=2'>valid project</a>",
      'validate', true
    );
    resetArticleSelector();
    $(".select2-selection--multiple").addClass('disabled');
    return true;
  } else {
    $(".validate").remove();
    $(".select2-selection--multiple").removeClass('disabled');
  }
}

function setupDateRangeSelector() {
  var dateRangeSelector = $(config.dateRangeSelector);
  dateRangeSelector.daterangepicker({
    startDate: moment().subtract(config.daysAgo, 'days'),
    minDate: config.minDate,
    maxDate: config.maxDate
  });
  dateRangeSelector.on('change', updateChart);
}

function setupArticleSelector () {
  var articleSelector = $(config.articleSelector);

  articleSelector.select2({
    placeholder: 'Type article names...',
    maximumSelectionLength: 10,
    // This ajax call queries the Mediawiki API for article name
    // suggestions given the search term inputed in the selector.
    ajax: {
      url: 'https://' + getProject() + '.org/w/api.php',
      dataType: 'jsonp',
      delay: 200,
      jsonpCallback: 'articleSuggestionCallback',
      data: function (search) {
        return {
          'action': 'opensearch',
          'format': 'json',
          'search': search.term,
          'redirects': 'return'
        };
      },
      processResults: function (data) {
        // Processes Mediawiki API results into Select2 format.
        var results = [];
        if (data && data[1].length) {
          results = data[1].map(function (elem) {
            return {
              id: elem.replace(/ /g, '_'),
              text: elem
            };
          });
        }
        return {results: results};
      },
      cache: true
    }
  });

  articleSelector.on('change', updateChart);
}

function bindListeners() {
  $(config.dateRangeSelector).on('change', function () {
    updateChart();
  });
  $(config.articleSelector).on('change', function () {
    updateChart();
  });
}

function unbindListeners() {
  $(config.dateRangeSelector).off('change');
  $(config.articleSelector).off('change');
}

// Select2 library prints "Uncaught TypeError: XYZ is not a function" errors
// caused by race conditions between consecutive ajax calls. They are actually
// not critical and can be avoided with this empty function.
function articleSuggestionCallback (data) {}

function resetArticleSelector () {
  var articleSelector = $(config.articleSelector);
  articleSelector.off('change');
  articleSelector.select2('val', null);
  articleSelector.select2('data', null);
  articleSelector.select2('destroy');
  setupArticleSelector();
  updateChart();
}

function setArticleSelectorDefaults (defaults) {
  // Caveat: This method only works with single-word article names.
  var articleSelectorQuery = config.articleSelector;
  defaults.forEach(function (elem) {
    var escapedText = $('<div>').text(elem).html();
    $('<option>' + escapedText + '</option>').appendTo(articleSelectorQuery);
  });
  var articleSelector = $(articleSelectorQuery);
  articleSelector.select2('val', defaults);
  articleSelector.select2('close');
}

function updateChart () {
  pushParams();
  // Collect parameters from inputs.
  var dateRangeSelector = $(config.dateRangeSelector);
  var startDate = dateRangeSelector.data('daterangepicker').startDate;
  var endDate = dateRangeSelector.data('daterangepicker').endDate;
  var articles = $(config.articleSelector).select2('val') || [];

  // Destroy previous chart, if needed.
  if(config.articleComparisonChart) {
    config.articleComparisonChart.destroy();
    delete config.articleComparisonChart;
  }

  if(articles.length) {
    $(".chart-container").addClass("loading");
  } else {
    $("#chart-legend").html("");
  }

  // Asynchronously collect the data from Analytics Query Service API,
  // process it to Chart.js format and initialize the chart.
  var labels = []; // Labels (dates) for the x-axis.
  var datasets = []; // Data for each article timeseries.
  articles.forEach(function (article, index) {
    var uriEncodedArticle = encodeURIComponent(article);
    // Url to query the API.
    var url = (
      'https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/' +
      getProject() + '/all-access/all-agents/' + uriEncodedArticle + '/daily/' +
      startDate.format(config.timestampFormat) + '/' + endDate.format(config.timestampFormat)
    );

    $.ajax({
      url: url,
      dataType: 'json',
      success: function(data) {
        fillInNulls(data, startDate, endDate);

        // Get the labels from the first call.
        if (labels.length === 0) {
          labels = data.items.map(function (elem) {
            return moment(elem.timestamp, config.timestampFormat).format('YYYY-MM-DD');
          });
        }

        // Build the article's dataset.
        var values = data.items.map(function (elem) { return elem.views; });
        var color = config.colors[index];
        datasets.push({
          label: article.replace(/_/g, ' '),
          fillColor: 'rgba(0,0,0,0)',
          strokeColor: color,
          pointColor: color,
          pointStrokeColor: '#fff',
          pointHighlightFill: '#fff',
          pointHighlightStroke: color,
          data: values,
          sum: values.reduce(function(a, b){return a+b;})
        });

        window.chartData = datasets;

        var template = "<b>Totals:</b><ul class=\"<%=name.toLowerCase()%>-legend\">" +
          "<% for (var i=0; i<datasets.length; i++){%>" +
            "<li><span class=\"indic\" style=\"background-color:<%=datasets[i].strokeColor%>\">" +
            "<a href='<%= getPageURL(datasets[i].label) %>'><%=datasets[i].label%></a></span> " +
            "<%= chartData[i].sum %></li><%}%></ul>";

        // When all article datasets have been collected,
        // initialize the chart.
        if (datasets.length == articles.length) {
          $(".chart-container").removeClass("loading");
          var lineData = {labels: labels, datasets: datasets};
          var options = {
            animation: true,
            animationEasing: "easeInOutQuart",
            bezierCurve: false,
            legendTemplate : template
          };
          $(".chart-container").html("");
          $(".chart-container").append("<canvas class='aqs-chart'>");
          var context = $(config.chart)[0].getContext('2d');
          config.articleComparisonChart = new Chart(context).Line(lineData, options);
          $("#chart-legend").html(config.articleComparisonChart.generateLegend());
        }
      },
      error: function(data) {
        if(data.status === 404) {
          $(".chart-container").html("");
          $(".chart-container").removeClass("loading");
          writeMessage("No data found for the page <a href='" + getPageURL(article) + "'>" + article + "</a>");
        }
      }
    });
  });
}

// Fills in null values to a timeseries, see:
// https://wikitech.wikimedia.org/wiki/Analytics/AQS/Pageview_API#Gotchas
function fillInNulls (data, startDate, endDate) {
  // Extract the dates that are already in the timeseries
  var alreadyThere = {};
  data.items.forEach(function (elem) {
    var date = moment(elem.timestamp, config.timestampFormat);
    alreadyThere[date] = elem;
  });
  data.items = [];
  // Reconstruct the timeseries adding nulls
  // for the dates that are not in the timeseries
  for (var date = moment(startDate); date.isBefore(endDate); date.add(1, 'd')) {
    if (alreadyThere[date]) {
      data.items.push(alreadyThere[date]);
    } else if (date != endDate) {
      data.items.push({
        timestamp: date.format(config.timestampFormat),
        views: null
      });
    }
  }
}

function writeMessage(message, className, clear) {
  if(clear) {
    $(".chart-container").removeClass("loading");
    $(".chart-container").html("");
  }
  $(".chart-container").append(
    "<p class='" + (className || '') + "'>" + message + "</p>"
  );
}

function pushParams() {
  var daterangepicker = $(config.dateRangeSelector).data('daterangepicker'),
    pages = $(config.articleSelector).select2('val') || [];

  var state = $.param({
    start: daterangepicker.startDate.format("YYYY-MM-DD"),
    end: daterangepicker.endDate.format("YYYY-MM-DD"),
    project: $(config.projectInput).val()
  }) + '&pages=' + pages.join('|');

  if (window.history && window.history.replaceState) {
    window.history.replaceState({}, 'Pageview comparsion', "#" + state);
  }
}

function popParams() {
  var params = parseHashParams();

  $(config.projectInput).val(params.project || 'en.wikipedia.org');
  if(validateProject()) return;

  var startDate = moment(params.start || moment().subtract(config.daysAgo, 'days')),
    endDate = moment(params.end || Date.now());

  $(config.dateRangeSelector).data('daterangepicker').setStartDate(startDate);
  $(config.dateRangeSelector).data('daterangepicker').setEndDate(endDate);

  resetArticleSelector();

  if(!params.pages || params.pages.length === 1 && !params.pages[0]) {
    params.pages = ['Cat', 'Dog'];
    setArticleSelectorDefaults(params.pages);
  } else {
    if(normalized) {
      params.pages = underscorePageNames(params.pages);
      setArticleSelectorDefaults(params.pages);
    } else {
      normalizePageNames(params.pages).then(function(data) {
        normalized = true;
        var pages = $.map(data.query.pages, function(page) {
          return page.title;
        });
        pages = underscorePageNames(pages);
        setArticleSelectorDefaults(pages);
      });
    }
  }
}

function normalizePageNames(pages) {
  return $.ajax({
    url: 'https://' + getProject() + '.org/w/api.php?action=query&prop=info&format=json&titles='+pages.join('|'),
    dataType: 'jsonp'
  });
}

function underscorePageNames(pages) {
  return $.map(pages, function(page) {
    page = page.charAt(0).toUpperCase() + page.slice(1);
    return decodeURIComponent(page.replace(/ /g, '_'));
  });
}

function parseHashParams() {
  var uri = decodeURI(location.hash.slice(1)),
    chunks = uri.split('&'),
    params = {};

  for(var i=0; i < chunks.length ; i++) {
    var chunk = chunks[i].split('=');

    if(chunk[0] === 'pages') {
      params.pages = chunk[1].split('|');
    } else {
      params[chunk[0]] = chunk[1];
    }
  }

  return params;
}

function exportCSV(e) {
  e.preventDefault();
  var csvContent = "data:text/csv;charset=utf-8,Page,Color,Sum,";

  var daterangepicker = $(config.dateRangeSelector).data('daterangepicker'),
    startMoment = jQuery.extend({}, daterangepicker.startDate),
    max = daterangepicker.endDate.diff(startMoment, 'days'),
    dateHeadings = [];
  for(var i=0; i<=max; i++) {
    dateHeadings.push(startMoment.format("YYYY-MM-DD"));
    startMoment.add(1, 'day');
  }

  dataRows = [];
  $.each(chartData, function(index, page) {
    var dataString = [
      page.label,
      page.strokeColor,
      page.sum
    ].concat(page.data).join(',');
    dataRows.push(dataString);
  });

  csvContent = csvContent + dateHeadings.join(',') + '\n' + dataRows.join('\n');

  var encodedUri = encodeURI(csvContent);
  window.open(encodedUri);
}

$(document).ready(function() {
  $.extend(Chart.defaults.global, {animation: false, responsive: true});

  setupProjectInput();
  setupDateRangeSelector();
  setupArticleSelector();
  popParams();

  // simple metric to see how many use it (pageviews of the pageview, a meta-pageview, if you will :)
  $.ajax({
    url: "/musikanimal/api/uses",
    method: 'PATCH',
    data : {
      tool: 'pageviews',
      type: 'form'
    }
  });

  $('.date-latest a').on('click', function(e) {
    var daterangepicker = $(config.dateRangeSelector).data('daterangepicker');
    daterangepicker.setStartDate(moment().subtract($(this).data('value'), 'days'));
    daterangepicker.setEndDate(moment());
    e.preventDefault();
  });

  $('.download-csv').on('click', exportCSV);

  // window.onpopstate = function() {
  //   popParams();
  // };
});
