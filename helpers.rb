module Helpers
  def repl_client(db = 'enwiki_p')
    @@repl_client ||= Auth.get_repl
    @@repl_client.set_db(db)
    @@repl_client
  end

  def repl_call(method, params)
    cache_response("#{method}#{params}") do
      res = repl_client.send(method, params)
      res = res.is_a?(Fixnum) ? res : res.to_a
      begin
        res.to_json
      rescue Encoding::UndefinedConversionError
        res.map! do |contrib|
          contrib.merge(
            'page_title' => contrib['page_title'].force_encoding('utf-8'),
            'rev_comment' => contrib['rev_comment'] ? contrib['rev_comment'].force_encoding('utf-8') : ''
          )
        end
        res.to_json
      end
    end
  end

  def api(db, method, params)
    params[:continue] = ''
    case db
    when :commons
      commons_mw.send(method, params)
    when :enwiki
      enwiki_mw.send(method, params)
    end
  end

  def cache_response(req, &res)
    @@redis_client ||= Auth.get_redis

    key = "ma-#{Digest::MD5.hexdigest(req.to_s)}"

    unless ret = @@redis_client.get(key)
      @@redis_client.set(key, ret = res.call)
      @@redis_client.expire(key, $CACHE_TIME)
    end

    # either a Hash or a Fixnum stored as a string
    JSON.parse(ret, quirks_mode: true) rescue ret.to_i
  end

  def disk_cache(filename, time = 3600, &res)
    filename = "#{PROJECT_ROOT}/disk_cache/#{filename}"
    if File.mtime(filename) < Time.now.utc - time
      ret = res.call

      cache_file = File.open(filename, 'r+')
      cache_file.write(ret.inspect)
      cache_file.close
    else
      ret = eval(File.open(filename).read)
    end

    ret
  end

  def commons_mw
    @@commons_mw ||= nil
    return @@commons_mw if @@commons_mw

    MediaWiki::Gateway.default_user_agent = 'MusikBot/1.1 (https://en.wikipedia.org/wiki/User:MusikBot/)'
    @@commons_mw ||= MediaWiki::Gateway.new('https://commons.wikimedia.org/w/api.php',
      bot: true,
      ignorewarnings: true
    )
    Auth.login(@@commons_mw)
    @@commons_mw
  end

  def enwiki_mw
    @@enwiki_mw ||= nil
    return @@enwiki_mw if @@enwiki_mw

    MediaWiki::Gateway.default_user_agent = 'MusikBot/1.1 (https://en.wikipedia.org/wiki/User:MusikBot/)'
    @@enwiki_mw ||= MediaWiki::Gateway.new('https://en.wikipedia.org/w/api.php',
      bot: true,
      ignorewarnings: true
    )
    Auth.login(@@enwiki_mw)
    @@enwiki_mw
  end

  def metadata_client
    @@metadata_client ||= Auth.get_metadata
  end

  def respond(data, opts = {})
    opts = {
      replag: true,
      status: 200,
      timing: true
    }.merge(opts || {})

    data.delete_if { |_k, v| v.nil? } if data.is_a?(Hash)

    if opts[:replag]
      lag = repl_client.replag
      data[:replication_lag] = lag.to_i if lag > 100
    end
    data[:elapsed_time] = (Time.now.to_f - @t1).round(3) if @t1 && opts[:timing]

    halt opts[:status], { 'Content-Type' => 'application/json' }, data.to_json
  end

  def respond_error(message, status = 400)
    message = message.is_a?(String) ? { error: message } : message
    halt status, { 'Content-Type' => 'application/json' }, message.to_json
  end

  def wikipedias
    %w(en sv de nl fr ru war ceb it es vi pl)
  end

  def record_use(tool, type)
    metadata_client.query("UPDATE views SET #{type} = #{type} + 1 WHERE tool = '#{tool}';")
  end

  def query(sql, *values)
    statement = metadata_client.prepare(sql)
    statement.execute(*values)
  end

  def site_map
    YAML.load(File.open('site_map.yml').read)
  end

  def user_info(username, groups = false, db = :enwiki)
    opts = {
      list: 'users',
      ususers: username
    }
    opts[:usprop] = 'groups' if groups

    data = api(db.to_sym, :custom_query, opts).elements['users'][0]

    res = {
      username: data.attributes['name'],
      id: data.attributes['userid'],
      anon: data.attributes['userid'].blank?
    }
    res[:groups] = ret.elements['groups'].collect { |ug| ug[0] } rescue [] if params['groups'].present?
    res
  end
end

class Object
  def present?
    !blank?
  end

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end
