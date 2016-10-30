class WikiTools < Sinatra::Application
  require 'nokogiri'
  require 'open-uri'
  app_name = 'Article analysis'

  namespace '/musikanimal/api/article_analysis' do
    # get '/article_analysis' do
    #   haml :article_analysis, locals: {
    #     app_name: app_name,
    #     project: params[:project].present? ? params[:project] : 'en.wikipedia.org',
    #     revision: params[:revision]
    #   }
    # end

    get '/basic_info' do
      [:pages].each do |param|
        unless params[param].present?
          return respond_error("Bad request! #{param} parameter is required")
        end
      end

      res = {
        pages: {}
      }

      if params[:start].present?
        begin
          start_date = Date.parse(params[:start])
        rescue
          return respond_error('Bad request! start parameter is invalid')
        end

        begin
          end_date = Date.parse(params[:end])
        rescue
          end_date = Date.today
        end

        if end_date < start_date
          return respond_error('Bad request! end must be after start')
        end

        res[:start] = start_date.strftime('%Y-%m-%d')
        res[:end] = end_date.strftime('%Y-%m-%d')
      end

      db = site_map.key(params[:project].sub(/.org$/, ''))

      params[:pages].split('|').each do |page|
        data = repl_client("#{db}_p").num_revisions_editors(
          page,
          res[:start],
          res[:end]
        )

        res[:pages][page] = data || {
          num_edits: 0,
          num_users: 0,
          missing: true
        }
      end

      respond(res, replag: false)
    end

    get '/edit_timeline' do
      [:page, :start].each do |param|
        unless params[param].present?
          return respond_error("Bad request! #{param} parameter is required")
        end
      end

      begin
        start_date = Date.parse(params[:start])
      rescue
        return respond_error('Bad request! start parameter is invalid')
      end

      begin
        end_date = Date.parse(params[:end])
      rescue
        end_date = Date.today
      end

      if end_date < start_date
        return respond_error('Bad request! end must be after start')
      end

      res = {
        page: params[:page],
        start: start_date.strftime('%Y-%m-%d'),
        end: end_date.strftime('%Y-%m-%d'),
        total_edits: nil,
        total_editors: nil,
        avg_daily_edits: nil,
        timeline: []
      }

      timeline_data = repl_client.edit_timeline(
        res[:page],
        res[:start],
        res[:end]
      )

      res[:total_edits] = timeline_data.length
      res[:total_editors] = timeline_data.map { |item| item['user'] }.uniq.length

      date_range = (Date.parse(res[:start])..Date.parse(res[:end])).to_a

      res[:avg_daily_edits] = (res[:total_edits] / date_range.length.to_f).round(2)

      date_range.each do |date|
        formatted_date = date.strftime('%Y-%m-%d')
        res[:timeline].push(
          date: formatted_date,
          count: timeline_data.count { |item| Date.parse(item['timestamp']) == date }
        )
      end

      respond(res)
    end

    get '/word_count' do
      unless params[:page].present?
        return respond_error('Bad request! page parameter is required')
      end

      escaped_page = URI.escape(params[:page])
      project = params[:project].present? ? params[:project] : 'en.wikipedia.org'

      chars, words = calculate_prose("https://#{project}/w/index.php?title=#{escaped_page}")

      res = {
        page: params[:page],
        characters: chars,
        words: words
      }

      if params[:revision].present?
        url = "https://#{project}/w/index.php?title=#{escaped_page}&oldid=#{params[:revision]}"
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
