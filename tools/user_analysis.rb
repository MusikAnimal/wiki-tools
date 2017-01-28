class WikiTools < Sinatra::Application
  require 'nokogiri'
  require 'open-uri'
  app_name = 'User analysis'

  namespace '/musikanimal/api/user_analysis' do
    get '/pages' do
      unless params[:username].present?
        return respond_error("Bad request! username parameter is required")
      end
      unless params[:project].present?
        return respond_error("Bad request! project parameter is required")
      end

      res = {
        username: params[:username],
        project: params[:project]
      }

      db = site_map.key(params[:project].sub(/.org$/, '')) + '_p'
      sql = "SELECT page_title AS title, rev_timestamp AS timestamp, " \
        "page_is_redirect AS redirect, page_len AS length, page_namespace AS namespace " \
        "FROM #{db}.page JOIN #{db}.revision_userindex ON page_id = rev_page " \
        "WHERE rev_user_text = ? AND rev_timestamp > 1 AND rev_parent_id = 0"

      if params[:namespace]
        sql += " AND page_namespace = #{params[:namespace].to_i}"
        res[:namespace] = params[:namespace]
      end
      if params[:redirects] == '1'
        sql += " AND page_is_redirect = 1"
        res[:redirects] = params[:redirects]
      elsif params[:redirects] != '2'
        sql += " AND page_is_redirect = 0"
      end

      sql += " LIMIT 20000"

      cache_response("#{db}#{params[:username]}") do
        statement = repl_client(db).client.prepare(sql)
        res[:pages] = statement.execute(params[:username].tr('_', ' ')).to_a

        begin
          res.to_json
        rescue Encoding::UndefinedConversionError
          res[:pages].map! do |page|
            page.merge(
              'title' => page['title'].force_encoding('utf-8')
            )
          end
          res.to_json
        end
      end

      respond(res)
    end
  end
end
