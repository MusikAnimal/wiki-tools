class WikiTools < Sinatra::Application
  app_name = 'BLP edit counter'
  contribs_fetch_size = 500
  contribs_page_size = 50

  namespace '/musikanimal' do
    get '/blp_edits' do
      haml :blp_edits, locals: {
        app_name: app_name,
        username: params[:username],
        contribs: params[:contribs]
      }
    end

    get '/blp_edits/about' do
      haml :'blp_edits/about', locals: {
        app_name: app_name,
        project_path: 'https://en.wikipedia.org'
      }
    end

    get '/api/blp_edits' do
      content_type :json

      unless params['username'].present?
        status 400
        return {
          error: 'Bad request! username parameter is required'
        }.to_json
      end

      res = {
        username: params['username'],
        total_count: repl_call(:count_all_edits, params['username']).to_i,
        blp_count: repl_call(:count_blp_edits, username: params['username']).to_i
      }

      if params['nonautomated'].present?
        res[:nonautomated_blp_count] = repl_call(:count_blp_edits,
          username: params['username'],
          nonautomated: true
        )
      end

      offset = params['offset'].to_i || 0
      range_offset = offset % contribs_fetch_size
      end_range_offset = range_offset + contribs_page_size - 1

      if params['contribs'].present?
        contribs = repl_call(:get_blp_edits,
          username: params['username'],
          offset: (offset / contribs_fetch_size.to_f).floor * contribs_fetch_size,
          limit: contribs_fetch_size,
          nonautomated: params['nonautomated'].present?
        )[range_offset..end_range_offset]

        if params['nonautomated'].present?
          res[:nonautomated_contribs] = contribs
        else
          res[:contribs] = contribs
        end
      end

      status 200
      normalize_data(res)
    end
  end
end
