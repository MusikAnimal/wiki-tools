class WikiTools < Sinatra::Application
  app_name = 'Nonautomated edit counter'
  contribs_fetch_size = 500
  contribs_page_size = 50

  namespace '/musikanimal' do
    before '/*' do
      params.delete_if { |_k, v| v == '' }
    end

    get '/nonautomated_edits' do
      namespace_id = params[:namespace].to_s.empty? ? nil : params[:namespace].to_i
      namespace_text = namespaces[namespace_id] || 'All'

      haml :nonautomated_edits, locals: {
        app_name: app_name,
        namespace: namespace_id,
        namespaces: namespaces,
        namespace_text: namespace_text,
        username: params[:username]
      }
    end

    get '/nonautomated_edits/about' do
      haml :'nonautomated_edits/about', locals: {
        app_name: app_name,
        tools: repl_client.tool_objects.to_a
      }
    end

    namespace '/api/nonautomated_edits' do
      get '' do
        if @user_id.blank?
          return respond_error('Bad request! username or user_id parameter is required')
        end

        params['namespace'] = params['namespace'] == '' ? nil : params['namespace']

        unless params['totalCountOnly'].present?
          count_data = repl_call(:count_edits,
            user_id: @user_id,
            namespace: params['namespace'],
            nonautomated: true
          ).to_i
        end

        if params['namespace'].present?
          total_edits = repl_call(:count_edits,
            user_id: @user_id,
            namespace: params['namespace']
          ).to_i
        else
          total_edits = repl_call(:count_all_edits, @user_id).to_i
        end

        @res.merge!(
          namespace: params['namespace'],
          namespace_text: namespaces[params['namespace'].to_s.empty? ? nil : params['namespace'].to_i],
          total_count: total_edits,
          automated_count: ((total_edits - count_data) rescue nil),
          nonautomated_count: (count_data rescue nil)
        )

        if params['contribs'].present?
          if total_edits > 50_000
            return respond(@res.merge(
              contribs: [],
              error: 'Query too large! Unable to retrieve non-automated contributions. User has over 50,000 edits. Batch querying will be implemented soon.'
            ), status: 501)
          else
            offset = params['offset'].to_i || 0
            range_offset = offset % contribs_fetch_size
            end_range_offset = range_offset + contribs_page_size - 1

            @res[:contribs] = repl_call(:get_edits,
              username: params['username'],
              namespace: params['namespace'],
              nonautomated: true,
              offset: (offset / contribs_fetch_size.to_f).floor * contribs_fetch_size,
              limit: contribs_fetch_size
            )[range_offset..end_range_offset]
          end
        end

        respond(@res)
      end

      get '/tools' do
        respond(repl_client.tool_objects,
          replag: false,
          timing: false
        )
      end

      get '/tools/:id' do
        res = @res || {}
        res[:tool_id] = params['id']
        res[:tool_name] = repl_client.tool_objects[params['id'].to_i][:name] rescue nil

        respond_error('Bad request! Invalid tool ID') unless res[:tool_name]

        if params[:namespace].present?
          unless namespaces[params['namespace'].to_i]
            return respond_error('Bad request! Invalid namespace ID')
          end

          res[:namespace] = params['namespace']
          res[:namespace_text] = namespaces[params['namespace']]
        end

        if @user_id.present?
          res[:count] = repl_client.count_edits(
            user_id: @user_id,
            namespace: params['namespace'],
            nonautomated: false,
            tool: params['id']
          )
          opts = { replag: params['noreplag'].blank? }
        else
          opts = {
            timing: false,
            replag: false
          }
        end

        respond(res, opts)
      end
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
