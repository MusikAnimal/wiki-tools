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
    namespaceText: namespaces[namespaceId],
    username: params[:username]
  }
end

get '/api/nonautomated_edits' do
  replClient = Auth.getRepl

  countData = replClient.countEdits({
    username: params["username"],
    namespace: params["namespace"],
    nonAutomated: true
  })

  res = {
    username: params["username"],
    namespace: params["namespace"],
    namespaceText: namespaces[params["namespace"].to_i],
    count: countData
  }

  if params["contribs"]
    if replClient.countAllEdits(params["username"]) > 50000
      status 501
      return res.merge({
        contribs: [],
        error: "Query too large! Unable to retrieve non-automated contributions. User has over 50,000 edits."
      }).to_json
    else
      contribsData = replClient.getEdits(
        username: params["username"],
        namespace: params["namespace"],
        offset: params["offset"],
        nonAutomated: true
      )
      res[:contribs] = contribsData.to_a
    end
  end

  if params["tools"]
    res[:tools] = replClient.countToolEdits({
      username: params["username"]
    }).to_a
  end

  status 200

  begin
    return res.to_json
  rescue Encoding::UndefinedConversionError
    res[:contribs].map! do |contrib|
      contrib.merge({
        contrib["page_title"] => contrib["page_title"].force_encoding('utf-8'),
        contrib["rev_comment"] => contrib["rev_comment"].force_encoding('utf-8')
      })
    end
    return res.to_json
  end
end

get '/api/nonautomated_edits/tools/:id' do
  content_type :json

  replClient = Auth.getRepl

  res = {
    username: params["username"],
    tool_id: params["id"],
    tool_name: replClient.toolNames[params["id"].to_i]
  }

  if params[:namespace]
    res[:namespace] = params["namespace"]
    res[:namespaceText] = namespaces[params["namespace"].to_i]
  end

  res[:count] = replClient.countEdits({
    username: params["username"],
    namespace: params["namespace"],
    nonAutomated: false,
    tool: params["id"]
  })

  status 200
  res.to_json
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