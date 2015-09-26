$LOAD_PATH << '.'
require 'sinatra'
require 'sinatra/namespace'
require 'haml'
require 'json'
require 'pry'
require 'mediawiki-gateway'
require 'auth.rb'

class WikiTools < Sinatra::Application
  configure :production do
    set :haml, ugly: true
    set :clean_trace, true
    $CACHE_TIME = 600
  end

  configure :development do
    $CACHE_TIME = 0
  end

  not_found do
    unless request.path =~ %r{\/api\/}
      status 404
      haml :'404', locals: { app_name: "Whoops, this page doesn't exist!" }
    end
  end
end

require_relative 'helpers'
WikiTools.helpers Helpers

require_relative 'tools/nonautomated_edits'
require_relative 'tools/sound_search'
