class WikiTools < Sinatra::Application
  app_name = 'Usage'

  namespace '/musikanimal/api/usage' do
    apps = %w(pageviews topviews langviews siteviews massviews redirectviews userviews)

    apps.each do |app|
      post("/#{app}/:project") { record_usage(app, params['project']) }
      get("/#{app}/:start/:end") { get_usage(app, params[:start], params[:end]) }
      get("/#{app}-projects") { get_project_usage(app) }
      post("/#{app}-test/:project") { record_usage("#{app}_test", params['project'], true) }
    end

    get("/topviews/false_positives") { get_topviews_false_positives(params) }
    post("/topviews/:project/false_positives") { record_topviews_false_positives(params) }

    # xtools
    post('/xtools/:project') { record_usage('xtools', params['project'], true) }
  end

  private

  def get_project_usage(tool)
    respond(
      query("SELECT * FROM #{tool}_projects").to_a,
      replag: false,
      timing: false
    )
  end

  def get_topviews_false_positives(params)
    false_positives = query(
      "SELECT page FROM topviews_false_positives WHERE project = ? AND date = ? AND platform = ? AND confirmed = 1",
      params[:project], params[:date], params[:platform]
    ).to_a.collect { |fp| fp['page'] }

    blacklist = query(
      "SELECT page FROM topviews_blacklist WHERE project = ? AND platform = ?",
      params[:project], params[:platform]
    ).to_a.collect { |fp| fp['page'] }

    respond(
      (false_positives + blacklist).uniq,
      replag: false,
      timing: false
    )
  end

  def record_topviews_false_positives(params)
    return unless params[:pages].is_a?(Array)

    where_clause = "WHERE project = ? AND page = ? AND platform = ? AND date = ?"
    where_args = [params[:project], nil, params[:platform], params[:date]]

    params[:pages].each do |page|
      where_args[1] = page
      page = metadata_client.escape(page)
      if query("SELECT * FROM topviews_false_positives #{where_clause}", *where_args).to_a.empty?
        query("INSERT INTO topviews_false_positives VALUES(NULL, ?, ?, 0, 0, ?, ?)", *where_args)
      else
        query("UPDATE topviews_false_positives SET count = count + 1 #{where_clause}", *where_args)
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

  def record_usage(tool, project, no_timeline = false, no_response = false)
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

    respond({}, replag: false) unless no_response
  end
end
