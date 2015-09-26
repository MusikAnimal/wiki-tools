module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-sass');

  grunt.initConfig({
    watch: {
      scripts: {
        files: ['javascripts/*.js', 'views/**/*.handlebars'],
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
            'javascripts/sound_search.js',
            'views/sound_search/*.handlebars'
          ]
        }
      }
    },
    sass: {
      dist: {
        options: {
          style: 'compressed',
          sourcemap: 'none'
        },
        files: [{
          expand: true,
          cwd: 'stylesheets',
          src: ['application.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
          expand: true,
          cwd: 'stylesheets/nonautomated_edits',
          src: ['nonautomated_edits.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
          expand: true,
          cwd: 'stylesheets/sound_search',
          src: ['sound_search.scss'],
          dest: 'public/musikanimal/sound_search',
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
