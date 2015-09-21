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

      files = commonsMW.custom_query({
        list: 'categorymembers',
        cmtitle: "Category:#{params[:composer]}",
        cmtype: 'file',
        cmlimit: 500
      })[0].to_a.collect { |cf| cf.attributes['title'] }.keep_if { |cf| cf.scan(/\.(?:ogg|flac|midi)$/i).any? }
      files.map! { |cf| { title: cf } }

      params['soundlist'] = params['soundlist'] == '' ? nil : params['soundlist']

      res = {
        composer: params[:composer]
      }

      if params[:restrict] == 'unused'
        res[:files] = []
        files.delete_if do |file|
          enwikiMW.custom_query({
            titles: file[:title],
            lhprop: 'title',
            lhshow: '!redirect',
            prop: 'linkshere',
            continue: ''
          })[0][0][0].length > 0 rescue false
        end
      elsif params[:restrict] == 'list'
        res[:files] = []
        binding.pry
        files.each do |file|
          links = enwikiMW.custom_query({
            titles: file[:title],
            lhprop: 'title',
            lhshow: '!redirect',
            prop: 'linkshere',
            continue: ''
          })[0][0][0].collect { |cf| cf.attributes['title'] }

          res[:files] << {
            title: file[:title],
            links: links
          }
        end
      elsif params[:soundlist]
        if sound_list_pages.include?(params[:soundlist])
          # FIXME: definitely needs caching!
          sound_list_source = enwikiMW.get('Wikipedia:Sound/list/#{params[:soundlist]}')
          sound_list = sound_list_source.scan(/\[\[media:\s*(.*?.(?:ogg|flac|midi))/i).flatten

          files.delete_if { |file| sound_list.include?(file[:title].gsub(/File:/, '')) }
          res[:files] = files
        else
          # error, should be in sound_list_pages
        end
      else
        res[:files] = files
      end

      status 200
      normalizeData(res)
    end
  end

  def sound_list_pages
    ['A', 'Ba', 'Bb–Bz', 'C', 'D–G', 'H', 'I–L', 'M', 'N–Q', 'R', 'S', 'T–Z']
  end
end
