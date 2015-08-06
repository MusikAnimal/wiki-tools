# app.rb
$LOAD_PATH << '.'

require 'sinatra'
require 'haml'
require 'json'
require 'pry'
require 'auth.rb'

get 'application.css' do
  scss :application
end

get 'application.js' do
  js :application
end

get '/' do
  haml :index
end

get '/nonautomated_edits' do
  namespaceId = params[:namespace].to_i || 0
  haml :nonautomated_edits, locals: {
    namespace: namespaceId,
    namespaces: namespaces,
    namespaceText: namespaces[namespaceId]
  }
end

post '/nonautomated_edits' do
  content_type :json

  replClient = Auth.getRepl

  data = replClient.countNonAutomatedNamespaceEdits(
    params["username"],
    params["namespace"]
  )

  status 200

  {count: data}.to_json
end

get '/counter' do
  haml :counter
end

not_found do
  haml :'404'
end

def namespaces
  {
    0 => "Main",
    1 => "Talk",
    2 => "User",
    3 => "User talk",
    4 => "Wikipedia",
    5 => "Wikipedia talk",
    6 => "File",
    7 => "File talk",
    8 => "MediaWiki",
    9 => "MediaWiki talk",
    10 => "Template",
    11 => "Template talk",
    12 => "Help",
    13 => "Help talk",
    14 => "Category",
    15 => "Category talk",
    100 => "Portal",
    101 => "Portal talk",
    108 => "Book",
    109 => "Book talk"
  }
end