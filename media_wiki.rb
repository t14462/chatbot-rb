require 'httparty'
require 'json'

module ChatBot
  class MediaWiki
    include HTTParty
    USER_AGENT = 'sactage/mediawiki_rb v0.1a'

    def initialize(url)
     self.class.base_uri url
    end

    def log_in(username, password)
      @username = username
      res = post(
        {
          :action => 'login',
          :lgname => @username,
          :lgpassword => password,
        }
      )
      data = JSON.parse(res.body, :symbolize_names => true)
      if data[:login][:result] != 'NeedToken'
        raise MediaWiki::LoginError, "Unrecognised error when fetching login token: #{data[:login][:result]}"
      end
      if not res.headers.key? 'set-cookie'
        raise MediaWiki::LoginError, 'No cookie header sent by server'
      end

      @cookie = res.headers['set-cookie']
      res = post({
        :action => 'login',
        :lgname => @username,
        :lgpassword => password,
        :lgtoken => data[:login][:token]
      })
      data = JSON.parse(res.body, :symbolize_names => true)
      if data[:login][:result] != 'Success'
        @cookie = ''
        raise MediaWiki::LoginError, "Error while logging in: #{data[:login][:result]}"
      end
      if not res.headers.key? 'set-cookie'
        @cookie = ''
        raise MediaWiki::LoginError, 'No cookie header sent by server'
      end
      @cookie = res.headers['set-cookie']

    end

    def post(options, path = '/api.php')
      if path == '/api.php'
        opts = {:body => {:format => 'json'}.merge(options), :headers => {'User-Agent' => USER_AGENT}}
      else
        opts = {:body => options, :headers => {'User-Agent' => USER_AGENT}}
      end

      if logged_in?
        opts[:headers]['Cookie'] = @cookie
      end

      self.class.post(path, opts)
    end

    def get(options, path = '/api.php')
      if path == '/api.php'
        opts = {:query => {:format => 'json'}.merge(options), :headers => {'User-Agent' => USER_AGENT}}
      else
        opts = {:query => options, :headers => {'User-Agent' => USER_AGENT}}
      end

      if logged_in?
        opts[:headers]['Cookie'] = @cookie
      end

      self.class.get(path, opts)
    end

    def logged_in?
      !@cookie.to_s.empty? and !@username.to_s.empty?
    end

    def query(options)
      res = get(
        options.merge({
          :action => 'query',
          :format => 'json'
        })
      )

      JSON.parse(res.body, :symbolize_names => true)
    end

    def edit(options)
      res = query(:titles => options[:title], :prop => 'info', :intoken => 'edit', :indexpageids => 1)
      page_id = res[:query][:pageids][0]
      token = res[:query][:pages][page_id]
      res = post(options.merge({:action => 'edit', :token => token}))
      res[:edit][:result] == 'Success'
    end

    def page_exists?(page)
      res = query(:titles => page)
      not res[:query][:pages].key? '-1'
    end

    def log_out
      post({:action => 'logout'})
      @username = ''
      @cookie = ''
    end
  end

  class MediaWiki::LoginError < StandardError

  end

end