module Repl

  class Session
    require 'mysql2'

    def initialize(username, password, host, db, port)
      @client = Mysql2::Client.new(
        host: host,
        username: username,
        password: password,
        database: db,
        port: port,
        reconnect: true
      )
      @db = db
    end

    # COUNTERS
    def countArticlesCreated(userName)
      count("SELECT count(*) FROM #{@db}.page JOIN #{@db}.revision_userindex ON page_id = rev_page " +
        "WHERE rev_user_text = \"#{userName}\" AND rev_timestamp > 1 AND rev_parent_id = 0 " +
        "AND page_namespace = 0 AND page_is_redirect = 0;")
    end

    def countAllEdits(userName)
      count("SELECT COUNT(*) FROM enwiki_p.revision_userindex WHERE rev_user_text=\"#{userName}\";")
    end

    def countEdits(opts)
      opts[:count] = true
      getEdits(opts)
    end

    # GETTERS
    def getArticlesCreated(userName)
      query = "SELECT page_title, rev_timestamp AS timestamp FROM #{@db}.page JOIN #{@db}.revision_userindex ON page_id = rev_page " +
        "WHERE rev_user_text = \"#{userName}\" AND rev_timestamp > 1 AND rev_parent_id = 0 " +
        "AND page_namespace = 0 AND page_is_redirect = 0;"
      puts query
      res = @client.query(query)
      articles = []
      res.each do |result|
        result["timestamp"] = DateTime.parse(result["timestamp"])
        articles << result
      end
      articles
    end

    def getEdits(opts)
      opts = {
        namespace: nil,
        nonAutomated: nil,
        tool: nil,
        limit: 50,
        offset: 0,
        count: false
      }.merge(opts)

      query = "SELECT " +
        (opts[:count] ? "COUNT(*) " : "#{revAttrs} ") +
        "FROM #{@db}.page " +
        "JOIN enwiki_p.revision_userindex ON page_id = rev_page " +
        "WHERE rev_user_text = \"#{opts[:username]}\" "+
        (opts[:namespace].to_s.empty? ? "" : "AND page_namespace = #{opts[:namespace]} ") +
        (!opts[:nonAutomated].nil? ? "AND rev_comment #{"NOT " if opts[:nonAutomated]}RLIKE \"#{[toolRegexes(opts[:tool])].join("|")}\" " : "") +
        (!opts[:count] ? "ORDER BY rev_id DESC LIMIT #{opts[:limit]} OFFSET #{opts[:offset]}" : "")

      opts[:count] ? count(query) : get(query)
    end

    def getTools
      res = []

      tools.each_with_index do |tool, toolId|
        res.push(tool.merge({
          id: toolId,
          regex: tool[:regex].gsub(/\\{2}/,"\\")
        }))
      end

      res
    end

    private

    def count(query)
      puts query
      @client.query(query).first.values[0].to_i
    end

    def get(query)
      puts query
      @client.query(query)
    end

    def revAttrs
      ["page_title", "page_namespace", "rev_id", "rev_page", "rev_timestamp", "rev_minor_edit", "rev_comment"].join(", ")
    end

    def tools(index = nil)
      tools = [
        {
          name: "Generic rollback",
          regex: "^Reverted edits by \\\\[\\\\[.*?\\\\|.*?\\\\]\\\\] \\\\(\\\\[\\\\[User talk:.*?\\\\|talk\\\\]\\\\]\\\\) to last version by .*",
          link: "WP:ROLLBACK"
        },
        {
          name: "Huggle",
          regex: "WP:HG",
          link: "WP:HG"
        },
        {
          name: "Twinkle",
          regex: "WP:TW|WP:TWINKLE",
          link: "WP:TW"
        },
        {
          name: "STiki",
          regex: "WP:STiki",
          link: "WP:STiki"
        },
        {
          name: "Igloo",
          regex: "Wikipedia:Igloo",
          link: "Wikipedia:Igloo"
        },
        {
          name: "Popups",
          regex: "Wikipedia:Tools\\\\/Navigation_popups|popups",
          link: "WP:POPUPS"
        },
        {
          name: "AFCH",
          regex: "WP:AFCH",
          link: "WP:AFCH"
        },
        {
          name: "AWB",
          regex: "Wikipedia:AWB|WP:AWB",
          link: "WP:AWB"
        },
        {
          name: "WP Cleaner",
          regex: "WP:CLEANER",
          link: "WP:CLEANER"
        },
        {
          name: "HotCat",
          regex: "WP:HOTCAT|WP:HC",
          link: "WP:HC"
        },
        {
          name: "reFill",
          regex: "WP:REFILL",
          link: "WP:REFILL"
        },
        {
          name: "WikiPatroller",
          regex: "User:Jfmantis/WikiPatroller",
          link: "User:Jfmantis/WikiPatroller"
        },
        {
          name: "User:Fox Wilson/delsort",
          regex: "Wikipedia:WP:FWDS|WP:FWDS",
          link: "WP:FWDS"
        }
      ]

      if index
        tools[index.to_i]
      else
        tools
      end
    end

    def toolRegexes(index = nil)
      regexes = tools.collect{|t| t[:regex]}

      if index
        regexes[index.to_i]
      else
        regexes
      end
    end
  end

end