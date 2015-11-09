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
      unless @user_id.present?
        respond_error('Bad request! username parameter is required')
      end

      @res.merge!(
        total_count: repl_call(:count_all_edits, @user_id).to_i,
        blp_count: repl_call(:count_blp_edits, user_id: @user_id).to_i
      )

      if params['nonautomated'].present?
        @res[:nonautomated_blp_count] = repl_call(:count_blp_edits,
          user_id: @user_id,
          nonautomated: true
        )
      end

      if params['contribs'].present?
        offset = params['offset'].to_i || 0
        range_offset = offset % contribs_fetch_size
        end_range_offset = range_offset + contribs_page_size - 1

        contribs = repl_call(:get_blp_edits,
          user_id: @user_id,
          offset: (offset / contribs_fetch_size.to_f).floor * contribs_fetch_size,
          limit: contribs_fetch_size,
          nonautomated: params['nonautomated'].present?
        )[range_offset..end_range_offset]

        if params['nonautomated'].present?
          @res[:nonautomated_contribs] = contribs
        else
          @res[:contribs] = contribs
        end
      end

      respond(@res)
    end
  end
end
