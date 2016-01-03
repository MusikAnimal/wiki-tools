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
    $CACHE_TIME = 0
  end

  before do
    if request.path_info.split('/')[2] == 'api'
      @t1 = Time.now.to_f
      if params['username'].present?
        @username = params['username']
        @res = { username: params['username'] }
      end
    end
  end

  get '/musikanimal' do
    record_use('index', 'form')
    haml :index, locals: {
      app_name: "MusikAnimal's tools",
      project_path: 'https://en.wikipedia.org'
    }
  end

  namespace '/musikanimal/api' do
    after '/*' do
      return if params['splat'].include?('uses')

      tool = params['splat'].first.split('/').first rescue nil
      record_use(tool, 'api') if tool && params['norecord'].blank?
    end

    patch '/uses' do
      if params['tool'].present? && params['type'].present?
        record_use(params['tool'], params['type'])
        status 204
      else
        status 304
      end
    end
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
