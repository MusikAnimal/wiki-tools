class WikiTools < Sinatra::Application
  require 'nokogiri'
  require 'open-uri'
  app_name = 'Article analysis'

  namespace '/musikanimal' do
    # get '/article_analysis' do
    #   haml :article_analysis, locals: {
    #     app_name: app_name,
    #     project: params[:project].present? ? params[:project] : 'en.wikipedia.org',
    #     revision: params[:revision]
    #   }
    # end

    get '/api/article_analysis' do
      unless params[:page].present?
        return respond_error('Bad request! page parameter is required')
      end

      project = params[:project].present? ? params[:project] : 'en.wikipedia.org'

      chars, words = calculate_prose("https://#{project}/wiki/#{params[:page]}")

      res = {
        page: params[:page],
        characters: chars,
        words: words
      }

      if params[:revision].present?
        url = "https://#{project}/w/index.php?title=#{params[:page]}&oldid=#{params[:revision]}"
        chars, words = calculate_prose(url)
        res[:revision] = {
          id: params[:revision].to_i,
          characters: chars,
          words: words
        }
      end

      respond(res)
    end
  end

  def calculate_prose(url)
    plist = Nokogiri::HTML(open(url)).css('#bodyContent').css('p')

    chars = 0
    words = 0

    plist.each do |p|
      c, w = get_readable(p)
      chars += c
      words += w
    end

    [chars, words]
  end

  def get_readable(node)
    chars = 0
    words = 0

    node.children.each do |child|
      if child.node_name == 'text'
        chars += child.text.length
        words += child.text.split(' ').length
      elsif !(class_name(child) =~ /reference|emplate/) && id_name(child) != 'coordinates'
        c, w = get_readable(child)
        chars += c
        words += w
      end
    end

    [chars, words]
  end

  def class_name(node)
    node.attributes['class'] ? node.attributes['class'].value : ''
  end

  def id_name(node)
    node.attributes['id'] ? node.attributes['id'].value : ''
  end
end
