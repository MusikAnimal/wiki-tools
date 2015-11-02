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
      content_type :json

      unless params['username'].present?
        status 400
        return {
          error: 'Bad request! username parameter is required'
        }.to_json
      end

      res = {
        username: params['username'],
        namespaces: {}
      }

      # TODO: check namespaces for this wiki!
      namespaces.keys.each do |namespace_id|
        if params['nonautomated'].present?
          res[:namespaces][namespaces[namespace_id]] = repl_client.count_edits(
            username: params['username'],
            namespace: namespace_id,
            nonautomated: true,
            count: true
          )
        else
          res[:namespaces][namespaces[namespace_id]] = repl_client.count_namespace_edits(params['username'], namespace_id)
        end
      end

      status 200
      normalize_data(res)
    end

    get '/api/namespace_counter/namespaces' do
      content_type :json

      status 200
      normalize_data(namespaces)
    end

    get '/api/namespace_counter/:id' do
      content_type :json

      unless params['username'].present? && params['id'].present?
        status 400
        return {
          error: 'Bad request! ID and username parameter are required'
        }.to_json
      end

      unless namespaces[params['id'].to_i]
        status 400
        return {
          error: 'Bad request! Invalid namespace ID'
        }.to_json
      end

      res = {
        username: params['username'],
        namespace: namespaces[params['id'].to_i]
      }

      if params['nonautomated'].present?
        res[:count] = repl_client.count_edits(
          username: params['username'],
          namespace: params['id'].to_i,
          nonautomated: true,
          count: true
        )
      else
        res[:count] = repl_client.count_namespace_edits(params['username'], params['id'].to_i)
      end

      status 200
      normalize_data(res)
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
