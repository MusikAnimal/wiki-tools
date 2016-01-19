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
    def count_articles_created(username)
      count("SELECT COUNT(*) FROM #{@db}.page JOIN #{@db}.revision_userindex ON page_id = rev_page " \
        "WHERE #{user_where_clause(username)} AND rev_timestamp > 1 AND rev_parent_id = 0 " \
        'AND page_namespace = 0 AND page_is_redirect = 0;')
    end

    def count_all_edits(username)
      count("SELECT COUNT(*) FROM enwiki_p.revision_userindex WHERE #{user_where_clause(username)};")
    end

    def count_blp_edits(opts)
      get_blp_edits({
        username: 'Example',
        count: true,
        nonautomated: false
      }.merge(opts))
    end

    def count_guideline_edits(opts)
      get_pg_edits({
        username: 'Example',
        count: true,
        nonautomated: false,
        regex: 'guidelines'
      }.merge(opts))
    end

    def count_policy_edits(opts)
      get_pg_edits({
        username: 'Example',
        count: true,
        nonautomated: false,
        regex: 'policies'
      }.merge(opts))
    end

    def count_edits(opts)
      opts[:count] = true
      get_edits(opts)
    end

    def count_category_edits(opts)
      opts[:count] = true
      get_category_edits(opts)
    end

    def count_namespace_edits(username, namespace = 0)
      namespace_str = namespace.is_a?(Array) ? "IN (#{namespace.join(',')})" : "= #{namespace}"
      count("SELECT COUNT(*) FROM #{@db}.page JOIN #{@db}.revision_userindex ON page_id = rev_page " \
        "WHERE #{user_where_clause(username)} AND rev_timestamp > 1 AND page_namespace #{namespace_str};")
    end

    # GETTERS
    def get_articles_created(username)
      query = "SELECT page_title, rev_timestamp AS timestamp FROM #{@db}.page JOIN #{@db}.revision_userindex ON page_id = rev_page " \
        "WHERE #{user_where_clause(username)} AND rev_timestamp > 1 AND rev_parent_id = 0 " \
        'AND page_namespace = 0 AND page_is_redirect = 0;'
      puts query
      res = @client.query(query)
      articles = []
      res.each do |result|
        result['timestamp'] = DateTime.parse(result['timestamp'])
        articles << result
      end
      articles
    end

    def get_blp_edits(opts = {})
      get_category_edits(opts.merge(categories: 'Living_people'))
    end

    def get_pg_edits(opts = {})
      opts = {
        count: false,
        nonautomated: nil,
        limit: 50,
        offset: 0,
        regex: 'policies|guidelines'
      }.merge(opts)

      query = 'SELECT ' +
        (opts[:count] ? 'COUNT(*) ' : 'rev_id, rev_comment, rev_timestamp, rev_minor_edit, page_title, cl_to ') +
        "FROM #{@db}.revision_userindex " \
        'JOIN enwiki_p.categorylinks JOIN enwiki_p.page ' \
        "WHERE #{user_where_clause(opts[:username])} " \
        'AND rev_timestamp > 0 ' \
        'AND page_namespace = 4 ' \
        'AND cl_from = rev_page ' \
        "AND cl_to RLIKE \"#{opts[:regex]}\" " + # FIXME: make case insensitive!
        'AND page_id = rev_page ' +
        (opts[:nonautomated] ? "AND rev_comment NOT RLIKE \"#{[tool_regexes(opts[:tool])].join('|')}\" " : '') +
        "ORDER BY rev_id DESC LIMIT #{opts[:limit]} OFFSET #{opts[:offset]}"

      opts[:count] ? count(query) : get(query)
    end

    def get_category_edits(opts = {})
      opts = {
        categories: [],
        count: false,
        nonautomated: nil,
        limit: 50,
        offset: 0
      }.merge(opts)

      query = 'SELECT ' +
        (opts[:count] ? 'COUNT(*) ' : 'rev_id, rev_comment, rev_timestamp, rev_minor_edit, page_title ') +
        "FROM #{@db}.revision_userindex " \
        'JOIN enwiki_p.categorylinks JOIN enwiki_p.page ' \
        "WHERE #{user_where_clause(opts[:username])} " \
        'AND rev_timestamp > 0 ' \
        'AND cl_from = rev_page ' \
        'AND (' + [opts[:categories]].flatten.map { |c| "cl_to = '#{c.gsub(' ', '_')}'" }.join(' OR ') + ') ' \
        'AND page_id = rev_page ' +
        (opts[:nonautomated] ? "AND rev_comment NOT RLIKE \"#{[tool_regexes(opts[:tool])].join('|')}\" " : '') +
        "ORDER BY rev_id DESC LIMIT #{opts[:limit]} OFFSET #{opts[:offset]}"

      opts[:count] ? count(query) : get(query)
    end

    # rubocop:disable CyclomaticComplexity
    # rubocop:disable AbcSize
    def get_edits(opts)
      opts = {
        namespace: nil,
        nonautomated: nil,
        tool: nil,
        limit: 50,
        offset: 0,
        count: false
      }.merge(opts)

      query = 'SELECT ' +
        (opts[:count] ? 'COUNT(*) ' : "#{rev_attrs} ") +
        "FROM #{@db}.page " \
        'JOIN enwiki_p.revision_userindex ON page_id = rev_page ' \
        "WHERE #{user_where_clause(opts[:username])} " \
        'AND rev_timestamp > 0 ' +
        (opts[:namespace].to_s.empty? ? '' : "AND page_namespace = #{opts[:namespace]} ") +
        (!opts[:nonautomated].nil? ? "AND rev_comment #{'NOT ' if opts[:nonautomated]}RLIKE \"#{[tool_regexes(opts[:tool])].join('|')}\" " : '') +
        (!opts[:count] ? "ORDER BY rev_id DESC LIMIT #{opts[:limit]} OFFSET #{opts[:offset]}" : '')

      opts[:count] ? count(query) : get(query)
    end

    def tool_objects
      res = []

      tools.each_with_index do |tool, toolId|
        res.push(tool.merge(
          id: toolId,
          regex: tool[:regex].gsub(/\\{2}/, '\\')
        ))
      end

      res
    end

    def get_backlinks(filename)
      get(
        'SELECT page_title ' \
        'FROM enwiki_p.imagelinks ' \
        'JOIN enwiki_p.page ' \
        "WHERE il_to = \"#{filename.gsub(/ /, '_').gsub(/\"/, '\"')}\" " \
        'AND page_id = il_from ' \
        'AND il_from_namespace = 0'
      )
    end

    def query(sql)
      puts sql
      @client.query(sql)
    end

    def replag
      query(
        'SELECT UNIX_TIMESTAMP() - UNIX_TIMESTAMP(rc_timestamp) AS replag ' \
        'FROM recentchanges_userindex ORDER BY rc_timestamp DESC LIMIT 1;'
      ).to_a[0]['replag'].to_f
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

    def user_where_clause(username)
      if username.is_a?(Fixnum)
        "rev_user = #{username}"
      else
        "rev_user_text = \"#{username}\""
      end
    end

    def rev_attrs
      %w(page_title page_namespace rev_id rev_page rev_timestamp rev_minor_edit rev_comment).join(', ')
    end

    # TODO: add caching, this doesn't change much
    # rubocop:disable MethodLength
    def tools(index = nil)
      contribs_link = '\\\\[\\\\[Special:(Contribs|Contributions)\\\\/.*?\\\\|.*?\\\\]\\\\]'
      tools = [
        {
          name: 'Generic rollback',
          regex: "^(\\\\[\\\\[Help:Reverting\\\\|Reverted\\\\]\\\\]|Reverted) edits by #{contribs_link} \\\\(\\\\[\\\\[User talk:.*?\\\\|talk\\\\]\\\\]\\\\) to last version by .*",
          link: 'WP:ROLLBACK'
        },
        {
          name: 'Undo',
          regex: "^Undid revision \\\\d+ by #{contribs_link}",
          link: 'Help:Undo'
        },
        {
          name: 'Pending changes revert',
          regex: "^(\\\\[\\\\[Help:Reverting\\\\|Reverted\\\\]\\\\]|Reverted) \\\\d+ (\\\\[\\\\[Wikipedia:Pending changes\\\\|pending\\\\]\\\\]|pending) edits? (to revision \\\\d+|by #{contribs_link})",
          link: 'Wikipedia:Reviewing'
        },
        {
          name: 'Page move',
          regex: '^.*?moved page \\\\[\\\\[(?!.*?WP:AFCH)|moved \\\\[\\\\[.*?\\\\]\\\\] to \\\\[\\\\[',
          link: 'Help:Move'
        },
        {
          name: 'Page curation',
          regex: 'using \\\\[\\\\[Wikipedia:Page Curation\\\\|Page Curation',
          link: 'Wikipedia:Page Curation'
        },
        {
          name: 'Twinkle',
          regex: 'WP:TW|WP:(TWINKLE|Twinkle)|WP:FRIENDLY|Wikipedia:Twinkle',
          link: 'WP:TW'
        },
        {
          name: 'Huggle',
          regex: 'WP:HG',
          link: 'WP:HG'
        },
        {
          name: 'STiki',
          regex: 'WP:STiki|WP:STIKI',
          link: 'WP:STiki'
        },
        {
          name: 'Igloo',
          regex: 'Wikipedia:Igloo',
          link: 'Wikipedia:Igloo'
        },
        {
          name: 'Popups',
          regex: 'Wikipedia:Tools\\\\/Navigation_popups|popups',
          link: 'WP:POPUPS'
        },
        {
          name: 'AFCH',
          regex: 'WP:AFCH|WP:AFCHRW',
          link: 'WP:AFCH'
        },
        {
          name: 'AWB',
          regex: 'Wikipedia:AWB|WP:AWB|Project:AWB',
          link: 'WP:AWB'
        },
        {
          name: 'WPCleaner',
          regex: 'WP:CLEANER|\\\\[\\\\[\\\\Wikipedia:DPL|\\\\[\\\\[WP:WCW\\\\]\\\\] project \\\\(',
          link: 'WP:CLEANER'
        },
        {
          name: 'HotCat',
          regex: 'using \\\\[\\\\[(WP:HOTCAT|WP:HC|Help:Gadget-HotCat)\\\\|HotCat',
          link: 'WP:HC'
        },
        {
          name: 'reFill',
          regex: 'User:Zhaofeng Li/Reflinks|WP:REFILL',
          link: 'WP:REFILL'
        },
        {
          name: 'Checklinks',
          regex: 'using \\\\[\\\\[w:WP:CHECKLINKS\\\\|Checklinks',
          link: 'WP:CHECKLINKS'
        },
        {
          name: 'Dab solver',
          regex: 'using \\\\[\\\\[(tools:~dispenser/view/Dab_solver|WP:DABSOLVER)\\\\|Dab solver' \
            '|(Disambiguated|Unlinked|Help needed): \\\\[\\\\[' \
            '|Disambiguated \\\\d+ links',
          link: 'WP:DABSOLVER'
        },
        {
          name: 'Dabfix',
          regex: 'using \\\\[\\\\[tools:~dispenser/cgi-bin/dabfix.py',
          link: 'toollabs:dispenser/cgi-bin/dabfix.py'
        },
        {
          name: 'Reflinks',
          regex: '\\\\[\\\\[(tools:~dispenser/view/Reflinks|WP:REFLINKS)\\\\|Reflinks',
          link: 'WP:REFLINKS'
        },
        {
          name: 'WikiPatroller',
          regex: 'User:Jfmantis/WikiPatroller',
          link: 'User:Jfmantis/WikiPatroller'
        },
        {
          name: 'delsort',
          regex: 'Wikipedia:WP:FWDS|WP:FWDS|\\\\(\\\\[\\\\[User:APerson/delsort\\\\|delsort.js',
          link: 'WP:DELSORT#Scripts and tools'
        },
        {
          name: 'Ohconfucius script',
          regex: '\\\\[\\\\[(User:Ohconfucius/.*?|WP:MOSNUMscript)\\\\|script',
          link: 'User:Ohconfucius/script'
        },
        {
          name: 'OneClickArchiver',
          regex: '\\\\[\\\\[(User:Equazcion/OneClickArchiver|User:Technical 13/1CA)\\\\|OneClickArchiver',
          link: 'User:Technical 13/1CA'
        },
        {
          name: 'editProtectedHelper',
          regex: 'WP:EPH|EPH',
          link: 'WP:EPH'
        },
        {
          name: 'WikiLove',
          regex: 'new WikiLove message',
          link: 'WP:LOVE'
        },
        {
          name: 'AutoEd',
          regex: 'using \\\\[\\\\[WP:AutoEd\\\\|AutoEd',
          link: 'WP:AutoEd'
        },
        {
          name: "Mike's Wiki Tool",
          regex: 'using \\\\[\\\\[User:MichaelBillington/MWT\\\\|MWT',
          link: "Wikipedia:Mike's Wiki Tool"
        },
        {
          name: 'Global replace',
          regex: '\\\\(\\\\[\\\\[c:GR\\\\|GR\\\\]\\\\]\\\\) ',
          link: 'commons:Commons:File renaming/Global replace'
        },
        {
          name: 'Admin actions',
          regex: '^(Protected|Changed protection).*?\\\\[[Ee]dit=|^Removed protection from|^Configured pending changes.*?\\\\[[Aa]uto-accept|^Reset pending changes settings',
          link: 'WP:ADMIN'
        },
        {
          name: 'CSD Helper',
          regex: '\\\\(\\\\[\\\\[User:Ale_jrb/Scripts\\\\|CSDH',
          link: 'User:Ale jrb/Scripts'
        },
        {
          name: 'Find link',
          regex: 'using \\\\[\\\\[User:Edward/Find link\\\\|Find link',
          link: 'User:Edward/Find link'
        },
        {
          name: 'responseHelper',
          regex: '\\\\(using \\\\[\\\\[User:MusikAnimal/responseHelper\\\\|responseHelper',
          link: 'User:MusikAnimal/responseHelper'
        },
        {
          name: 'Advisor.js',
          regex: '\\\\(using \\\\[\\\\[User:Cameltrader#Advisor.js\\\\|Advisor.js',
          link: 'User:Cameltrader/Advisor'
        },
        {
          name: 'AfD closures',
          regex: '^\\\\[\\\\[Wikipedia:Articles for deletion/.*?closed as',
          link: 'WP:AfD'
        },
        {
          name: 'Sagittarius',
          regex: '\\\\(\\\\[\\\\[User:Kephir/gadgets/sagittarius\\\\|',
          link: 'User:Kephir/gadgets/sagittarius'
        },
        {
          name: 'Redirect',
          regex: '\\\\[\\\\[WP:AES\\\\|←\\\\]\\\\]Redirected page to \\\\[\\\\[.*?\\\\]\\\\]',
          link: 'Wikipedia:Redirect'
        },
        {
          name: 'Dashes',
          regex: 'using a \\\\[\\\\[User:GregU/dashes.js\\\\|script',
          link: 'User:GregU/dashes.js'
        },
        {
          name: 'SPI Helper',
          regex: '^(Archiving case (to|from)|Adding sockpuppetry (tag|block notice) per) \\\\[\\\\[Wikipedia:Sockpuppet investigations',
          link: 'User:Timotheus Canens/spihelper.js'
        },
        {
          name: 'User:Doug/closetfd.js',
          regex: '\\\\(using \\\\[\\\\[User:Doug/closetfd.js',
          link: 'User:Doug/closetfd.js'
        },
        {
          name: 'Cat-a-lot',
          regex: '^\\\\[\\\\[Help:Cat-a-lot\\\\|Cat-a-lot\\\\]\\\\]:',
          link: 'Help:Cat-a-lot'
        },
        {
          name: 'autoFormatter',
          regex: 'using \\\\[\\\\[:meta:User:TMg/autoFormatter',
          link: 'meta:User:TMg/autoFormatter'
        },
        {
          name: 'Citation bot',
          regex: '\\\\[\\\\[WP:UCB\\\\|Assisted by Citation bot',
          link: 'WP:UCB'
        },
        {
          name: 'Red Link Recovery Live',
          regex: '\\\\[\\\\[w:en:WP:RLR\\\\|You can help!',
          link: 'toollabs:tb-dev/RLRL'
        },
        {
          name: 'Script Installer',
          regex: '\\\\[\\\\[User:Equazcion/ScriptInstaller\\\\|Script Installer',
          link: 'User:Equazcion/ScriptInstaller'
        },
        {
          name: 'findargdups',
          regex: '\\\\[\\\\[:en:User:Frietjes/findargdups',
          link: 'User:Frietjes/findargdups'
        },
        {
          name: 'closemfd.js',
          regex: '\\\\(using \\\\[\\\\[User:Doug/closemfd.js',
          link: 'User:Doug/closemfd.js'
        },
        {
          name: 'DisamAssist',
          regex: 'using \\\\[\\\\[User:Qwertyytrewqqwerty/DisamAssist',
          link: 'User:Qwertyytrewqqwerty/DisamAssist'
        }
      ]

      if index
        tools[index.to_i]
      else
        tools
      end
    end

    def tool_regexes(index = nil)
      regexes = tools(nil).collect { |t| t[:regex] }

      if index
        regexes[index.to_i]
      else
        regexes
      end
    end
  end
end
