class WikiTools < Sinatra::Application
  namespace '/musikanimal' do
    get '/sound_search' do
      haml :sound_search, locals: {
        app_name: 'Sound search',
        soundlists: sound_list_pages,
        soundlist: sound_list_pages.include?(params[:soundlist]) ? params[:soundlist] : nil
      }
    end

    get '/api/sound_search' do
      content_type :json

      file_names = commonsMW.custom_query(
        list: 'categorymembers',
        cmtitle: "Category:#{params[:composer]}",
        cmtype: 'file',
        cmlimit: 500
      )[0].to_a.collect { |cf| cf.attributes['title'] }.keep_if { |cf| cf.scan(/\.(?:ogg|flac|midi)$/i).any? }

      files = commonsMW.custom_query(
        titles: file_names.join('|'),
        prop: 'imageinfo',
        iiprop: 'url',
        continue: ''
      )[0].map do |file_upload|
        {
          title: file_upload.attributes['title'],
          source: file_upload[0][0].attributes['url']
        }
      end

      params['soundlist'] = params['soundlist'] == '' ? nil : params['soundlist']

      if params[:restrict] == 'unused'
        files.delete_if do |file|
          enwikiMW.custom_query(
            titles: file[:title],
            lhprop: 'title',
            lhshow: '!redirect',
            prop: 'linkshere',
            continue: ''
          )[0][0][0].length > 0 rescue false
        end
      elsif params[:restrict] == 'list'
        get_links(files.collect { |t| t[:title] }).each_with_index do |page, index|
          if links = page[0]
            files[index][:links] = links.collect { |l| l.attributes['title'] }
          else
            files[index][:links] = []
          end
        end
      elsif params[:restrict] == 'soundlist'
        if sound_list_pages.include?(params[:soundlist])
          # FIXME: definitely needs caching!
          sound_list_source = enwikiMW.get("Wikipedia:Sound/list/#{params[:soundlist]}")
          sound_list = sound_list_source.scan(/\[\[media:\s*(.*?.(?:ogg|flac|midi))/i).flatten

          files.delete_if { |file| sound_list.include?(file[:title].gsub(/File:/, '')) }
        else
          # error, should be in sound_list_pages
        end
      end

      res = {
        composer: params[:composer],
        files: files
      }

      status 200
      normalizeData(res)
    end
  end

  def get_links(file_names)
    enwikiMW.custom_query(
      titles: file_names.join('|'),
      lhprop: 'title',
      lhshow: '!redirect',
      prop: 'linkshere',
      continue: ''
    )[0]
  end

  def sound_list_pages
    ['A', 'Ba', 'Bb–Bz', 'C', 'D–G', 'H', 'I–L', 'M', 'N–Q', 'R', 'S', 'T–Z']
  end
end
