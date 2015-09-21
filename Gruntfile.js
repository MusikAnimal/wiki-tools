module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  // grunt.loadNpmTasks('hbsfy');
  // grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-sass');

  grunt.initConfig({
    watch: {
      scripts: {
        files: 'javascripts/*.js',
        tasks: ['browserify']
      },
      css: {
        files: 'stylesheets/*.scss',
        tasks: ['sass']
      }
    },
    browserify: {
      options: {
        transform: ['hbsfy']
      },
      dist: {
        files: {
          'public/musikanimal/application.js': ['javascripts/wt.js'],
          'public/musikanimal/nonautomated_edits.js': [
            'javascripts/nonautomated_edits.js',
            'views/nonautomated_edits/*.handlebars'
          ],
          'public/musikanimal/sound_search.js': [
            'javascripts/sound_search.js'
          ]
        }
      }
    },
    // concat: {
    //   options: {
    //     separator: ";"
    //   },
    //   dist: {
    //     src: ["public/musikanimal/application.js"],
    //     dest: "public/musikanimal/application.js"
    //   }
    // },
    sass: {
      dist: {
        options: {
          style: 'compressed'
        },
        files: [{
          expand: true,
          cwd: 'stylesheets',
          src: ['*.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }]
      }
    },
    uglify: {
      options: {
        compress: true
      },
      all: {
        files: {
          'public/musikanimal/application.js': ['public/musikanimal/application.js']
        }
      }
    }
  });

  var tasks = ['browserify', 'sass'];

  var fs = require('fs');
  fs.readFile('env', 'utf8', function(err, data) {
    if(data.indexOf(':production') !== -1) {
      tasks.push('uglify:all');
    }
  });

  grunt.registerTask('default', tasks);
};
