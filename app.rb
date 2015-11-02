$LOAD_PATH << '.'
require 'sinatra'
require 'sinatra/namespace'
require 'haml'
require 'json'
require 'pry'
require 'mediawiki-gateway'
require 'auth.rb'

class WikiTools < Sinatra::Application
  before { request.path_info.sub! %r{/$}, '' }

  configure :production do
    set :haml, ugly: true
    set :clean_trace, true
    $CACHE_TIME = 600
  end

  configure :development do
    $CACHE_TIME = 100
  end

  get '/musikanimal' do
    haml :index, locals: {
      app_name: "MusikAnimal's tools",
      project_path: 'https://en.wikipedia.org'
    }
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
require_relative 'tools/blp_edits'
require_relative 'tools/policy_edits'
require_relative 'tools/category_edits'
require_relative 'tools/namespace_counter'
require_relative 'tools/sound_search'
