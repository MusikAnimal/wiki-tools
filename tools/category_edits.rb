class WikiTools < Sinatra::Application
  app_name = 'Category edit counter'
  contribs_fetch_size = 500
  contribs_page_size = 50

  namespace '/musikanimal' do
    get '/category_edits' do
      haml :category_edits, locals: {
        app_name: app_name,
        username: params[:username],
        contribs: params[:contribs] == '' ? false : true
      }
    end

    get '/category_edits/about' do
      haml :'category_edits/about', locals: {
        app_name: app_name,
        project_path: 'https://en.wikipedia.org'
      }
    end

    get '/api/category_edits' do
      content_type :json

      missing = %w(username category).select { |name| params[name].to_s.empty? }
      if missing.any?
        status 400
        return {
          error: "Bad request! Missing required parameters: #{missing.join(', ')}"
        }.to_json
      end

      categories = params['category'].split('|')

      res = {
        username: params['username'],
        total_count: repl_call(:count_all_edits, params['username']).to_i
      }

      prefix = params['nonautomated'].present? ? 'nonautomated_' : ''

      if params['counts'].present?
        res[:categories] = []
        total_category_count = 0

        categories.each do |category|
          obj = { name: category }
          obj["#{prefix}count".to_sym] = repl_call(:count_category_edits,
            username: params['username'],
            categories: category,
            nonautomated: params['nonautomated'].present?
          ).to_i
          total_category_count += obj["#{prefix}count".to_sym]
          res[:categories] << obj
        end

        res["total_#{prefix}category_count".to_sym] = total_category_count
      else
        res[:categories] = categories
        res["total_#{prefix}category_count".to_sym] = repl_call(:count_category_edits,
          username: params['username'],
          categories: categories,
          nonautomated: params['nonautomated'].present?
        )
      end

      if params['contribs'].present?
        offset = params['offset'].to_i || 0
        range_offset = offset % contribs_fetch_size
        end_range_offset = range_offset + contribs_page_size - 1

        contribs = repl_call(:get_category_edits,
          username: params['username'],
          offset: (offset / contribs_fetch_size.to_f).floor * contribs_fetch_size,
          limit: contribs_fetch_size,
          categories: categories,
          nonautomated: params['nonautomated'].present?
        )[range_offset..end_range_offset]

        res["#{prefix}contribs".to_sym] = contribs
      end

      status 200
      normalize_data(res)
    end

    get '/api/category_edits/category/:name' do
      content_type :json

      if params['username'].to_s.empty?
        status 400
        return {
          error: 'Bad request! username parameter is required'
        }.to_json
      end

      res = {
        username: params['username'],
        category_name: params['name'].gsub(' ', '_')
      }

      count = repl_call(:count_category_edits,
        username: params['username'],
        categories: params['name'],
        nonautomated: params['nonautomated'].present?
      )

      if params['nonautomated'].present?
        res[:nonautomated_count] = count
      else
        res[:count] = count
      end

      status 200
      normalize_data(res)
    end
  end
end
