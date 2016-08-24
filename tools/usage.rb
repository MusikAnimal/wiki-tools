class WikiTools < Sinatra::Application
  namespace '/musikanimal/api/usage' do
    # pageviews
    patch('/pageviews/:project') { record_usage('pageviews', params['project']) }
    get('/pageviews/:start/:end') { get_usage('pageviews', params[:start], params[:end]) }

    # topviews
    patch('/topviews/:project') { record_usage('topviews', params['project']) }
    get('/topviews/:start/:end') { get_usage('topviews', params[:start], params[:end]) }

    # langviews
    patch('/langviews/:project') { record_usage('langviews', params['project']) }
    get('/langviews/:start/:end') { get_usage('langviews', params[:start], params[:end]) }

    # siteviews
    patch('/siteviews/:project') { record_usage('siteviews', params['project']) }
    get('/siteviews/:start/:end') { get_usage('siteviews', params[:start], params[:end]) }

    # massviews
    patch('/massviews/:project') { record_usage('massviews', params['project']) }
    get('/massviews/:start/:end') { get_usage('massviews', params[:start], params[:end]) }

    # redirectviews
    patch('/redirectviews/:project') { record_usage('redirectviews', params['project']) }
    get('/redirectviews/:start/:end') { get_usage('redirectviews', params[:start], params[:end]) }

    # xtools
    patch('/xtools/:project') { record_usage('xtools', params['project'], true) }
  end

  private

  def get_usage(tool, start_date, end_date)
    data = query("SELECT * FROM #{tool}_timeline WHERE date >= ? AND date <= ? ORDER BY date ASC", start_date, end_date).to_a
    new_data = []

    date = Date.parse(start_date)
    while date <= Date.parse(end_date)
      day_data = data.find { |d| d['date'] == date }
      if day_data
        day_data.delete('id')
        new_data << day_data
      else
        new_data << {
          'date' => date,
          'count' => 0
        }
      end
      date += 1
    end

    respond(
      new_data,
      replag: false,
      timing: false
    )
  end

  def record_usage(tool, project, no_timeline = false)
    if query("SELECT * FROM #{tool}_projects WHERE project = ?", project).to_a.empty?
      query("INSERT INTO #{tool}_projects VALUES(NULL, ?, 1)", project)
    else
      query("UPDATE #{tool}_projects SET count = count + 1 WHERE project = ?;", project)
    end

    unless no_timeline
      date = Date.today.to_s
      if query("SELECT * FROM #{tool}_timeline WHERE date = ?", date).to_a.empty?
        query("INSERT INTO #{tool}_timeline VALUES(NULL, ?, 1)", date)
      else
        query("UPDATE #{tool}_timeline SET count = count + 1 WHERE date = ?;", date)
      end
    end
  end
end
