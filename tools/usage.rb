class WikiTools < Sinatra::Application
  app_name = 'Usage'

  namespace '/musikanimal/api/usage' do
    apps = %w(pageviews topviews langviews siteviews massviews redirectviews)

    apps.each do |app|
      post("/#{app}/:project") { record_usage(app, params['project']) }
      get("/#{app}/:start/:end") { get_usage(app, params[:start], params[:end]) }
      post("/#{app}-test/:project") { record_usage("#{app}_test", params['project'], true) }
    end

    get("/pageviews/:project") { record_pageviews_and_get_false_positives(params['project'], params['page']) }
    get("/topviews/:project") { get_topviews_false_positives(params['project']) }
    post("/topviews/:project/false_positives") { record_topviews_false_positives(params['project'], params['pages']) }

    # xtools
    post('/xtools/:project') { record_usage('xtools', params['project'], true) }
  end

  private

  def record_pageviews_and_get_false_positives(project, page)

  end

  def get_topviews_false_positives(project)
    false_positives = query("SELECT page FROM topviews_false_positives WHERE project = ? AND confirmed = 1", project).to_a

    if query("SELECT * FROM topviews_projects WHERE project = ?", project).to_a.empty?
      query("INSERT INTO topviews_projects VALUES(NULL, ?, 1)", project)
    else
      query("UPDATE topviews_projects SET count = count + 1 WHERE project = ?;", project)
    end

    date = Date.today.to_s
    if query("SELECT * FROM topviews_timeline WHERE date = ?", date).to_a.empty?
      query("INSERT INTO topviews_timeline VALUES(NULL, ?, 1)", date)
    else
      query("UPDATE topviews_timeline SET count = count + 1 WHERE date = ?;", date)
    end

    respond(
      false_positives.collect { |fp| fp['page'] },
      replag: false,
      timing: false
    )
  end

  def record_topviews_false_positives(project, pages)
    return unless params[:pages].is_a?(Array)
    params[:pages].each do |page|
      page = metadata_client.escape(page)
      if query("SELECT * FROM topviews_false_positives WHERE project = ? AND page = ?", project, page).to_a.empty?
        query("INSERT INTO topviews_false_positives VALUES(NULL, ?, ?, 0, 0)", project, page)
      else
        query("UPDATE topviews_false_positives SET count = count + 1 WHERE project = ? AND page = ?", project, page)
      end
    end
    halt 204
  end

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
