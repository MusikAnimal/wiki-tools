class WikiTools < Sinatra::Application
  app_name = 'Namespace edit counter'

  namespace '/musikanimal' do
    get '/namespace_counter' do
      haml :namespace_counter, locals: {
        app_name: app_name,
        username: params[:username]
      }
    end

    get '/namespace_counter/about' do
      haml :'namespace_counter/about', locals: {
        app_name: app_name,
        project_path: 'https://en.wikipedia.org'
      }
    end

    get '/api/namespace_counter' do
      unless @user_id.present?
        return respond_error('Bad request! username parameter is required')
      end

      @res[:namespaces] = {}
      @t1 = Time.now.to_f

      # TODO: check namespaces for this wiki!
      namespaces.keys.each do |namespace_id|
        if params['nonautomated'].present?
          @res[:namespaces][namespaces[namespace_id]] = repl_client.count_edits(
            user_id: @user_id,
            namespace: namespace_id,
            nonautomated: true,
            count: true
          )
        else
          @res[:namespaces][namespaces[namespace_id]] = repl_client.count_namespace_edits(@user_id, namespace_id)
        end
      end

      respond(@res)
    end

    get '/api/namespace_counter/namespaces' do
      respond(namespaces,
        replag: false,
        timing: false
      )
    end

    get '/api/namespace_counter/:id' do
      unless @user_id.present? && params['id'].present?
        return respond_error('Bad request! ID and username parameters are required')
      end

      unless namespaces[params['id'].to_i]
        return respond_error('Bad request! Invalid namespace ID')
      end

      @t1 = Time.now.to_f

      @res[:namespace] = namespaces[params['id'].to_i]

      if params['nonautomated'].present?
        @res[:count] = repl_client.count_edits(
          user_id: @user_id,
          namespace: params['id'].to_i,
          nonautomated: true,
          count: true
        )
      else
        @res[:count] = repl_client.count_namespace_edits(@user_id, params['id'].to_i)
      end

      respond(@res, replag: params['noreplag'].blank?)
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
