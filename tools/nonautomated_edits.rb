class WikiTools < Sinatra::Application
  namespace '/musikanimal' do
    CONTRIBS_FETCH_SIZE = 500
    CONTRIBS_PAGE_SIZE = 50

    before '/*' do
      params.delete_if { |_k, v| v == '' }
    end

    get '/nonautomated_edits' do
      namespace_id = params[:namespace].to_s.empty? ? nil : params[:namespace].to_i
      namespace_text = namespaces[namespace_id] || 'All'

      haml :nonautomated_edits, locals: {
        app_name: 'Nonautomated edit counter',
        namespace: namespace_id,
        namespaces: namespaces,
        namespace_text: namespace_text,
        username: params[:username]
      }
    end

    get '/nonautomated_edits/about' do
      haml :about, locals: {
        tools: replClient.getTools.to_a
      }
    end

    # get '/edit_summary_search' do
    #   namespace_id = params[:namespace] ? params[:namespace].to_i : nil
    #   namespace_text = namespaces[namespace_id] || "All"

    #   haml :edit_summary_search, locals: {
    #     namespace: namespace_id,
    #     namespaces: namespaces,
    #     namespace_text: namespace_text,
    #     username: params[:username]
    #   }
    # end

    get '/api/nonautomated_edits' do
      content_type :json

      if params['username'].to_s.empty?
        status 400
        return {
          error: 'Bad request! username parameter is required'
        }.to_json
      end

      params['namespace'] = params['namespace'] == '' ? nil : params['namespace']

      unless params['totalCountOnly']
        count_data = replCall(:countEdits, {
          username: params['username'],
          namespace: params['namespace'],
          nonAutomated: true,
          includeRedirects: !!params['redirects']
        }).to_i
      end

      if params['namespace']
        total_edits = replCall(:countEdits, {
          username: params['username'],
          namespace: params['namespace']
        }).to_i
      else
        total_edits = replCall(:countAllEdits, params['username']).to_i
      end

      res = {
        username: params['username'],
        namespace: params['namespace'],
        namespace_text: namespaces[params['namespace'].to_s.empty? ? nil : params['namespace'].to_i],
        total_count: total_edits,
        automated_count: ((total_edits - count_data) rescue nil),
        nonautomated_count: (count_data rescue nil)
      }

      if params['contribs']
        if total_edits > 50_000
          status 501
          return normalizeData(res.merge({
            contribs: [],
            error: 'Query too large! Unable to retrieve non-automated contributions. User has over 50,000 edits. Batch querying will be implemented soon.'
          }))
        else
          offset = params['offset'].to_i || 0
          range_offset = offset % CONTRIBS_FETCH_SIZE

          res[:contribs] = replCall(:getEdits, {
            username: params['username'],
            namespace: params['namespace'],
            nonAutomated: true,
            offset: (offset / CONTRIBS_FETCH_SIZE.to_f).floor * CONTRIBS_FETCH_SIZE,
            limit: CONTRIBS_FETCH_SIZE
          })[range_offset..(range_offset + CONTRIBS_PAGE_SIZE - 1)]
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
        tool_id: params['id'],
        tool_name: replClient.getTools[params['id'].to_i][:name]
      }

      if params[:namespace]
        res[:namespace] = params['namespace']
        res[:namespace_text] = namespaces[params['namespace']]
      end

      if params['username']
        res[:username] = params['username']
        res[:count] = replClient.countEdits({
          username: params['username'],
          namespace: params['namespace'],
          nonAutomated: false,
          tool: params['id']
        })
      end

      status 200
      normalizeData(res)
    end
  end

  def namespaces
    {
      0 => 'Main',
      1 => 'Talk',
      2 => 'User',
      3 => 'User talk',
      4 => 'Wikipedia',
      5 => 'Wikipedia talk',
      6 => 'File',
      7 => 'File talk',
      8 => 'MediaWiki',
      9 => 'MediaWiki talk',
      10 => 'Template',
      11 => 'Template talk',
      12 => 'Help',
      13 => 'Help talk',
      14 => 'Category',
      15 => 'Category talk',
      100 => 'Portal',
      101 => 'Portal talk',
      108 => 'Book',
      109 => 'Book talk'
    }
  end
end
