class WikiTools < Sinatra::Application
  namespace '/musikanimal' do
    get 'api/blp_edits/:username' do
      content_type  :json

      status 200
      normalizeData(res)
    end
  end
end