module Helpers
  def repl_client
    @repl_client ||= Auth.getRepl
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
            'rev_comment' => contrib['rev_comment'].force_encoding('utf-8')
          )
        end
        res.to_json
      end
    end
  end

  def api(db, method, params)
    return api_call(db, method, params, 0)
  end

  def api_call(db, method, params, throttle)
    return nil if throttle > 3

    begin
      case db
      when :commons
        commons_mw.send(method, params)
      when :enwiki
        enwiki_mw.send(method, params)
      end

    rescue => e
      binding.pry
      sleep(((throttle + 2) * 2) + 1)
      api(method, params, throttle + 1)
    end
  end

  def cache_response(req, &res)
    @redis_client ||= Auth.getRedis

    key = "ma-#{Digest::MD5.hexdigest(req.to_s)}"

    unless ret = @redis_client.get(key)
      @redis_client.set(key, ret = res.call)
      @redis_client.expire(key, $CACHE_TIME)
    end

    # either a Hash or a Fixnum stored as a string
    JSON.parse(ret) rescue ret.to_i
  end

  def commons_mw
    @commons_mw ||= MediaWiki::Gateway.new('https://commons.wikimedia.org/w/api.php')
  end

  def enwiki_mw
    @enwiki_mw ||= MediaWiki::Gateway.new('https://en.wikipedia.org/w/api.php')
  end

  def normalize_data(data)
    data.delete_if { |_k, v| v.nil? } if data.is_a?(Hash)
    data.to_json
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
