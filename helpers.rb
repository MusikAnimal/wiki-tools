module Helpers
  def replClient
    @@replClient ||= Auth.getRepl
  end

  def replCall(method, params)
    cacheResponse("#{method}#{params}") do
      res = replClient.send(method, params)
      res = res.is_a?(Fixnum) ? res : res.to_a

      begin
        res.to_json
      rescue Encoding::UndefinedConversionError
        res.map! do |contrib|
          contrib.merge({
            "page_title" => contrib["page_title"].force_encoding('utf-8'),
            "rev_comment" => contrib["rev_comment"].force_encoding('utf-8')
          })
        end
        res.to_json
      end
    end
  end

  def cacheResponse(req, &res)
    @redisClient ||= Auth.getRedis

    key = "ma-#{Digest::MD5.hexdigest(req.to_s)}"

    unless ret = @redisClient.get(key)
      @redisClient.set(key, ret = res.call)
      @redisClient.expire(key, $CACHE_TIME)
    end

    # either a Hash or a Fixnum stored as a string
    JSON.parse(ret) rescue ret.to_i
  end

  def commonsMW
    @commonsMW ||= MediaWiki::Gateway.new("https://commons.wikimedia.org/w/api.php")
  end

  def enwikiMW
    @enwikiMW ||= MediaWiki::Gateway.new("https://en.wikipedia.org/w/api.php")
  end

  def normalizeData(data)
    data.delete_if { |k,v| v.nil? } if data.is_a?(Hash)
    data.to_json
  end
end