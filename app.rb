# app.rb
$LOAD_PATH << '.'

require 'sinatra'
require 'sinatra/namespace'
require 'haml'
require 'json'
require 'pry'
require 'auth.rb'

namespace '/musikanimal' do
  CONTRIBS_FETCH_SIZE = 500
  CONTRIBS_PAGE_SIZE = 50
  CACHE_TIME = eval(File.open("env").read) == :production ? 600 : 0

  before '/*' do
    params.delete_if {|k,v| v == ""}
  end

  get '/' do
    redirect '/musikanimal/nonautomated_edits'
  end

  get '/nonautomated_edits' do
    namespaceId = params[:namespace].to_s.empty? ? nil : params[:namespace].to_i
    namespaceText = namespaces[namespaceId] || "All"

    haml :nonautomated_edits, locals: {
      namespace: namespaceId,
      namespaces: namespaces,
      namespaceText: namespaceText,
      username: params[:username]
    }
  end

  get '/nonautomated_edits/about' do
    haml :about, locals: {
      tools: replClient.getTools.to_a
    }
  end

  # get '/edit_summary_search' do
  #   namespaceId = params[:namespace] ? params[:namespace].to_i : nil
  #   namespaceText = namespaces[namespaceId] || "All"

  #   haml :edit_summary_search, locals: {
  #     namespace: namespaceId,
  #     namespaces: namespaces,
  #     namespaceText: namespaceText,
  #     username: params[:username]
  #   }
  # end

  get '/api/nonautomated_edits' do
    content_type :json

    if params["username"].to_s.empty?
      status 400
      return {
        error: "Bad request! username parameter is required"
      }.to_json
    end

    params["namespace"] = params["namespace"] == "" ? nil : params["namespace"]

    if !params["totalCountOnly"]
      countData = replCall(:countEdits, {
        username: params["username"],
        namespace: params["namespace"],
        nonAutomated: true,
        includeRedirects: !!params["redirects"]
      }).to_i
    end

    if params["namespace"]
      totalEdits = replCall(:countEdits, {
        username: params["username"],
        namespace: params["namespace"]
      }).to_i
    else
      totalEdits = replCall(:countAllEdits, params["username"]).to_i
    end

    res = {
      username: params["username"],
      namespace: params["namespace"],
      namespace_text: namespaces[params["namespace"].to_s.empty? ? nil : params["namespace"].to_i],
      total_count: totalEdits,
      automated_count: ((totalEdits - countData) rescue nil),
      nonautomated_count: (countData rescue nil)
    }

    if params["contribs"]
      if totalEdits > 50000
        status 501
        return normalizeData(res.merge({
          contribs: [],
          error: "Query too large! Unable to retrieve non-automated contributions. User has over 50,000 edits. Batch querying will be implemented soon."
        }))
      else
        offset = params["offset"].to_i || 0
        rangeOffset = offset % CONTRIBS_FETCH_SIZE

        res[:contribs] = replCall(:getEdits, {
          username: params["username"],
          namespace: params["namespace"],
          nonAutomated: true,
          offset: (offset / CONTRIBS_FETCH_SIZE.to_f).floor * CONTRIBS_FETCH_SIZE,
          limit: CONTRIBS_FETCH_SIZE
        })[rangeOffset..(rangeOffset + CONTRIBS_PAGE_SIZE)]
      end
    end

    status 200
    normalizeData(res)
  end

  get '/api/nonautomated_edits/tools' do
    content_type :json

    res = replClient.getTools

    status 200
    normalizeData(res)
  end

  get '/api/nonautomated_edits/tools/:id' do
    content_type :json

    res = {
      tool_id: params["id"],
      tool_name: replClient.getTools[params["id"].to_i][:name]
    }

    if params[:namespace]
      res[:namespace] = params["namespace"]
      res[:namespace_text] = namespaces[params["namespace"]]
    end

    if params["username"]
      res[:username] = params["username"]
      res[:count] = replClient.countEdits({
        username: params["username"],
        namespace: params["namespace"],
        nonAutomated: false,
        tool: params["id"]
      })
    end

    status 200
    normalizeData(res)
  end
end

not_found do
  haml :'404'
end

def replCall(method, params)
  cacheResponse("#{method}#{params}") do
    res = replClient.send(method, params)
    res = res.is_a?(Fixnum) ? res : res.to_a

    begin
      res.to_json
    rescue Encoding::UndefinedConversionError
      res.map! do |contrib|
        contrib.merge({
          "page_title" => contrib["page_title"].force_encoding('utf-8'),
          "rev_comment" => contrib["rev_comment"].force_encoding('utf-8')
        })
      end
      res.to_json
    end
  end
end

def replClient
  @@replClient ||= Auth.getRepl
end

def cacheResponse(req, &res)
  @@redisClient ||= Auth.getRedis

  key = "ma-#{Digest::MD5.hexdigest(req.to_s)}"

  unless ret = @@redisClient.get(key)
    @@redisClient.set(key, ret = res.call)
    @@redisClient.expire(key, CACHE_TIME)
  end

  # either a Hash or a Fixnum stored as a string
  JSON.parse(ret) rescue ret.to_i
end

def normalizeData(data)
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
