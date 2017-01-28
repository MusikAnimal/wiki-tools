class WikiTools < Sinatra::Application
  require 'nokogiri'
  require 'httparty'
  app_name = 'Pageviews'

  namespace '/musikanimal/api/pageviews' do
    get '/top_search/:project/:date/:page' do
      binding.pry
    end
  end
end
