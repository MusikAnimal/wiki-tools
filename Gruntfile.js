module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-sass');

  grunt.initConfig({
    watch: {
      scripts: {
        files: ['javascripts/**/*.js', 'views/**/*.handlebars'],
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
          'public/musikanimal/application.js': ['javascripts/shared/*.js'],
          'public/musikanimal/nonautomated_edits.js': [
            'javascripts/nonautomated_edits.js',
            'views/nonautomated_edits/*.handlebars'
          ],
          'public/musikanimal/sound_search.js': [
            'javascripts/sound_search.js',
            'views/sound_search/*.handlebars'
          ],
          'public/musikanimal/blp_edits.js': [
            'javascripts/blp_edits.js',
            'views/blp_edits/*.handlebars'
          ],
          'public/musikanimal/policy_edits.js': [
            'javascripts/policy_edits.js',
            'views/policy_edits/*.handlebars'
          ],
          'public/musikanimal/category_edits.js': [
            'javascripts/category_edits.js',
            'views/category_edits/*.handlebars'
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
          src: ['index.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
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
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
          expand: true,
          cwd: 'stylesheets/blp_edits',
          src: ['blp_edits.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
          expand: true,
          cwd: 'stylesheets/policy_edits',
          src: ['policy_edits.scss'],
          dest: 'public/musikanimal',
          ext: '.css'
        }, {
          expand: true,
          cwd: 'stylesheets/category_edits',
          src: ['category_edits.scss'],
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
          'public/musikanimal/application.js': ['public/musikanimal/application.js'],
          'public/musikanimal/nonautomated_edits.js' : ['public/musikanimal/nonautomated_edits.js'],
          'public/musikanimal/sound_search.js' : ['public/musikanimal/sound_search.js'],
          'public/musikanimal/blp_edits.js' : ['public/musikanimal/blp_edits.js'],
          'public/musikanimal/policy_edits.js' : ['public/musikanimal/policy_edits.js'],
          'public/musikanimal/category_edits.js' : ['public/musikanimal/category_edits.js']
        }
      }
    }
  });

  var tasks = ['browserify', 'sass', 'uglify:all'];

  grunt.registerTask('default', tasks);
};
