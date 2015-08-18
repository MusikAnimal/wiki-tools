# app.rb
$LOAD_PATH << '.'

require 'sinatra'
require 'sinatra/namespace'
require 'haml'
require 'json'
require 'pry'
require 'auth.rb'

namespace '/musikanimal' do
  before '/*' do
    @@replClient ||= Auth.getRepl
    params.delete_if {|k,v| v == ""}
  end

  get '/' do
    redirect :nonautomated_edits
  end

  get '/nonautomated_edits' do
    namespaceId = params[:namespace] ? params[:namespace].to_i : nil
    namespaceText = namespaces[namespaceId] || "All"

    haml :nonautomated_edits, locals: {
      namespace: namespaceId,
      namespaces: namespaces,
      namespaceText: namespaceText,
      username: params[:username]
    }
  end

  get '/api/nonautomated_edits' do
    content_type :json

    if params["username"].to_s.empty?
      status 400
      return {
        error: "Bad request! username parameter is required"
      }.to_json
    end

    params["namespace"] = params["namespace"] == "" ? nil : params["namespace"]

    countData = @@replClient.countEdits({
      username: params["username"],
      namespace: params["namespace"],
      nonAutomated: true
    })

    totalEdits = @@replClient.countAllEdits(params["username"])

    res = {
      username: params["username"],
      namespace: params["namespace"],
      namespace_text: namespaces[params["namespace"].to_s.empty? ? nil : params["namespace"].to_i],
      total_count: totalEdits,
      nonautomated_count: countData
    }

    if params["contribs"]
      if totalEdits > 50000
        status 501
        return sendData(res.merge({
          contribs: [],
          error: "Query too large! Unable to retrieve non-automated contributions. User has over 50,000 edits. Batch querying will be implemented soon."
        }))
      else
        contribsData = @@replClient.getEdits(
          username: params["username"],
          namespace: params["namespace"],
          offset: params["offset"] || 0,
          nonAutomated: true
        )
        res[:contribs] = contribsData.to_a
      end
    end

    status 200

    begin
      return sendData(res)
    rescue Encoding::UndefinedConversionError
      res[:contribs].map! do |contrib|
        contrib.merge({
          "page_title" => contrib["page_title"].force_encoding('utf-8'),
          "rev_comment" => contrib["rev_comment"].force_encoding('utf-8')
        })
      end
      return sendData(res)
    end
  end

  get '/api/nonautomated_edits/tools' do
    content_type :json

    res = @@replClient.getTools

    status 200
    sendData(res)
  end

  get '/api/nonautomated_edits/tools/:id' do
    content_type :json

    res = {
      tool_id: params["id"],
      tool_name: @@replClient.getTools[params["id"].to_i][:name]
    }

    if params[:namespace]
      res[:namespace] = params["namespace"]
      res[:namespace_text] = namespaces[params["namespace"]]
    end

    if params["username"]
      res[:username] = params["username"]
      res[:nonautomated_count] = @@replClient.countEdits({
        username: params["username"],
        namespace: params["namespace"],
        nonAutomated: false,
        tool: params["id"]
      })
    end

    status 200
    sendData(res)
  end
end

not_found do
  haml :'404'
end

def sendData(data)
  data.delete_if { |k,v| v.nil? } if data.is_a?(Hash)
  data.to_json
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