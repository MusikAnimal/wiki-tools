class WikiTools < Sinatra::Application
  app_name = 'Usage'

  namespace '/musikanimal/api/usage' do
    apps = %w(pageviews topviews langviews siteviews massviews redirectviews)

    apps.each do |app|
      post("/#{app}/:project") { record_usage(app, params['project']) }
      get("/#{app}/:start/:end") { get_usage(app, params[:start], params[:end]) }
      post("/#{app}-test/:project") { record_usage("#{app}_test", params['project'], true) }
    end

    # xtools
    post('/xtools/:project') { record_usage('xtools', params['project'], true) }
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

    respond({})
  end
end
