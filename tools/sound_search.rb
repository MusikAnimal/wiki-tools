class WikiTools < Sinatra::Application
  namespace '/musikanimal' do
    get '/sound_search' do
      haml :sound_search, locals: {
        app_name: 'Sound search',
        list: params[:list].present? ? params[:list] : 'all',
        soundlists: sound_list_pages,
        soundlist: sound_list_pages.include?(params[:soundlist]) ? params[:soundlist] : nil
      }
    end

    get '/sound_search/about' do
      haml :'sound_search/about', locals: {
        app_name: 'Sound search'
      }
    end

    namespace '/api/sound_search' do
      get '' do
        content_type :json

        files = get_sound_files("Category:#{params[:composer]}").uniq.map { |sf| { title: sf } }
        total_file_count = files.length

        if params[:list] == 'unused'
          files.select! { |f| get_backlinks(f[:title].gsub(/^File:/, '')).length == 0 }
        end

        res = {
          composer: params[:composer],
          files: files || [],
          total_files: total_file_count
        }

        if files.nil?
          status 500
          res[:error] = 'API failure!'
        else
          status 200
        end

        normalize_data(res)
      end

      get '/info/:filenames' do
        content_type :json

        filenames = params[:filenames].split('|').map { |fn| fn =~ /^File:/ ? fn : fn.prepend('File:') }

        data = commons_mw.custom_query(
          titles: filenames.join('|'),
          prop: 'imageinfo',
          iiprop: 'url|extmetadata',
          continue: ''
        )

        res = { title: data.attributes['title'] }

        if data.nil?
          res[:error] = 'API failure!'
          status 500
        else
          data = data.elements['pages'][0]

          if data[0]
            imageinfo = data.elements['imageinfo'][0]
            metadata = imageinfo.elements['extmetadata']
            res[:source] = imageinfo.attributes['url']
            res[:description] = metadata.elements['ImageDescription'].attributes['value'] rescue ''
            res[:author] = metadata.elements['Artist'].attributes['value'] rescue ''
            res[:date] = metadata.elements['DateTimeOriginal'].attributes['value'] rescue ''
            status 200
          else
            res[:error] = 'File not found'
            status 404
          end
        end

        normalize_data(res)
      end

      get '/backlinks/:filename' do
        content_type :json

        params[:filename].gsub(/^File:/, '')

        res = {
          title: params[:filename].gsub('_', ' '),
          links: get_backlinks(params[:filename]).map { |l| l.force_encoding('utf-8') }
        }

        status 200
        normalize_data(res)
      end
    end
  end

  def get_backlinks(filename)
    filename.gsub!(/^File:/, '')
    repl_client.get_backlinks(filename).to_a.collect { |p| p['page_title'].gsub('_', ' ') }
  end

  def get_sound_files(category)
    file_names = []

    params = {
      list: 'categorymembers',
      cmtitle: category,
      cmtype: 'file|subcat',
      cmlimit: 500
    }

    # FIXME: might fail with empty categories
    data = api(:commons, :custom_query, params)

    return false unless data

    category_members = data[0].to_a
    category_members = category_members.collect { |cf| cf.attributes['title'] }
    file_names = category_members.select { |cf| cf.scan(/\.(?:ogg|flac|midi)$/i).any? }

    category_members.select { |cm| cm =~ /^Category:/ }.each do |subcat|
      if %w(composition audio flac midi ogg).any? { |keyword| subcat.downcase.include?(keyword) }
        file_names.concat(get_sound_files(subcat))
      end
    end

    file_names
  end

  def sound_list_pages
    ['A', 'Ba', 'Bb–Bz', 'C', 'D–G', 'H', 'I–L', 'M', 'N–Q', 'R', 'S', 'T–Z']
  end
end
