class WikiTools < Sinatra::Application
  CONTRIBS_FETCH_SIZE = 500
  CONTRIBS_PAGE_SIZE = 50

  namespace '/musikanimal' do
    get '/blp_edits' do
      haml :blp_edits, locals: {
        app_name: 'BLP Edits',
        username: params[:username],
        contribs: params[:contribs] == '' ? false : true
      }
    end

    get '/blp_edits/about' do
      haml :'blp_edits/about', locals: {
        app_name: 'BLP Edits',
        project_path: 'https://en.wikipedia.org'
      }
    end

    get '/api/blp_edits' do
      content_type :json

      if params['username'].to_s.empty?
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

      if !!params['nonautomated']
        res[:nonautomated_blp_count] = repl_call(:count_blp_edits,
          username: params['username'],
          nonautomated: true
        )
      end

      offset = params['offset'].to_i || 0
      range_offset = offset % CONTRIBS_FETCH_SIZE
      end_range_offset = range_offset + CONTRIBS_PAGE_SIZE - 1

      if params['contribs']
        contribs = repl_call(:get_blp_edits,
          username: params['username'],
          offset: (offset / CONTRIBS_FETCH_SIZE.to_f).floor * CONTRIBS_FETCH_SIZE,
          limit: CONTRIBS_FETCH_SIZE,
          nonautomated: !!params['nonautomated']
        )[range_offset..end_range_offset]

        if !!params['nonautomated']
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
