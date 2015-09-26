class WikiTools < Sinatra::Application
  # http://quarry.wmflabs.org/query/5238
  namespace '/musikanimal' do
    get 'api/blp_edits/:username' do
      content_type  :json

      status 200
      normalize_data(res)
    end
  end
end