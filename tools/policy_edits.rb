class WikiTools < Sinatra::Application
  app_name = 'Policies and guidelines edit counter'
  contribs_fetch_size = 500
  contribs_page_size = 50

  namespace '/musikanimal' do
    get '/policy_edits' do
      haml :policy_edits, locals: {
        app_name: app_name,
        username: params[:username],
        contribs: params[:contribs] == '' ? false : true
      }
    end

    get '/policy_edits/about' do
      haml :'policy_edits/about', locals: {
        app_name: app_name,
        project_path: 'https://en.wikipedia.org'
      }
    end

    get '/api/policy_edits' do
      if @user_id.blank?
        respond_error('Bad request! username or user_id parameter is required')
      end

      @res[:total_count] = repl_call(:count_all_edits, @user_id).to_i

      if params['nonautomated'].present?
        @res[:nonautomated_policy_count] = repl_call(:count_policy_edits,
          user_id: @user_id,
          nonautomated: true
        )
        @res[:nonautomated_guideline_count] = repl_call(:count_guideline_edits,
          user_id: @user_id,
          nonautomated: true
        )
      else
        @res[:policy_count] = repl_call(:count_policy_edits, user_id: @user_id).to_i
        @res[:guideline_count] = repl_call(:count_guideline_edits, user_id: @user_id).to_i
      end

      if params['contribs']
        offset = params['offset'].to_i || 0
        range_offset = offset % contribs_fetch_size
        end_range_offset = range_offset + contribs_page_size - 1

        contribs = repl_call(:get_pg_edits,
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
