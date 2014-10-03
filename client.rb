require 'httparty'
require 'media_wiki'
require 'logger'
require_relative './plugin'
require_relative './util'

$logger = Logger.new(STDERR)
$logger.level = Logger::WARN

module Chatbot
  class Client
    include HTTParty

    USER_AGENT = 'sactage/chatbot-rb v2.0.0 (fyi socket.io sucks) [http://github.com/sactage/chatbot-rb]'
    CONFIG_FILE = 'config.yml'

    attr_accessor :session, :clientid, :handlers, :config, :userlist, :api, :threads
    attr_reader :plugins

    def initialize
      unless File.exists? CONFIG_FILE
        $logger.fatal "Config: #{CONFIG_FILE} not found!"
        exit
      end

      @config = YAML::load_file CONFIG_FILE
      @base_url = @config.key?('dev') ? "http://localhost:8080" : "http://#{@config['wiki']}.wikia.com"
      @api = MediaWiki::Gateway.new @base_url + '/api.php'
      @api.login(@config['user'], @config['password'])
      @t = 0
      @headers = {
          'User-Agent' => USER_AGENT,
          'Cookie' => @api.cookies.map { |k, v| "#{k}=#{v};" }.join(' '),
          'Content-Type' => 'application/octet-stream',
          'Accept' => '*/*',
          'Pragma' => 'no-cache',
          'Cache-Control' => 'no-cache'
      }
      @userlist = {}
      @userlist_mutex = Mutex.new
      @running = true
      fetch_chat_info
      @threads = []
      @plugins = []
      @handlers = {
          :message => [],
          :join => [],
          :part => [],
          :kick => [],
          :logout => [],
          :ban => [],
          :update_user => [],
          :quitting => []
      }
    end

    def register_plugins(*plugins)
      plugins.each do |plugin|
        @plugins << plugin.new(self)
        @plugins.last.register
      end
    end

    def save_config
      File.open(CONFIG_FILE, File::WRONLY) { |f| f.write(@config.to_yaml) }
    end

    def fetch_chat_info
      res = HTTParty.get("#{@base_url}/wikia.php?controller=Chat&format=json", :headers => @headers)
      data = JSON.parse(res.body, :symbolize_names => true)
      @key = data[:chatkey]
      @server = data[:nodeInstance]
      @room = data[:roomId]
      @mod = data[:isChatMod]
      @initialized = false
      @request_options = {
          :name => @config['user'],
          :EIO => 2,
          :transport => 'polling',
          :key => @key,
          :roomId => @room,
          :serverId => @server
      }
      if @config.key?('dev')
        self.class.base_uri "http://#{data[:nodeHostname]}:#{data[:nodePort]}/"
      else
        self.class.base_uri "http://#{data[:nodeHostname]}/"
      end
      res = get
      @request_options[:sid] = JSON.parse(res.body[5, res.body.size-1], :symbolize_names => true)[:sid]
      @headers['Cookie'] = res.headers['set-cookie']
    end

    def get(path: '/socket.io/')
      opts = @request_options.merge({:t => Time.now.to_ms.to_s + '-' + @t.to_s})
      @t +=1
      self.class.get(path, :query => opts, :headers => @headers)
    end

    def post(body)
      body = Util::format_message(body == :ping ? '2' : '42' + ["message", {:id => nil, :attrs => body}.to_json].to_json)
      opts = @request_options.merge({:t => Time.now.to_ms.to_s + '-' + @t.to_s})
      @t += 1
      self.class.post('/socket.io/', :query => opts, :body => body, :headers => @headers)
    end

    def run!
      while @running
        begin
          res = get
          body = res.body
          spl = body.match(/(?:\x00.+?#{255.chr}(.+?))+$/)
          next unless spl
          @running = false if body.include? "Session ID unknown" # This essentially means chat forcibly removed us.
          spl.captures.each do |message|
            @threads << Thread.new(message) {
              on_socket_message(message.gsub(/^42/, ''))
            } if message.match(/^42/)
          end
        rescue => e
          $logger.fatal e
          @running = false
        end
      end
      @handlers[:quitting].each { |handler| handler.call(nil) }
      @threads.each { |thr| thr.join }
    end

    def on_socket_connect
      $logger.info 'Connected to chat!'
    end

    def on_socket_message(msg)
      begin
        json = JSON.parse(msg)[1]
        json['data'] = JSON.parse(json['data'])
        if json['event'] == 'chat:add' and not json['data']['id'].nil?
          json['event'] = 'message'
        elsif json['event'] == 'updateUser'
          json['event'] = 'update_user'
        end
        begin
          self.method("on_chat_#{json['event']}".to_sym).call(json['data'])
        rescue NameError
          $logger.debug 'ignoring un-used event'
        end
        @handlers[json['event'].to_sym].each { |handler| handler.call(json['data']) } if json['event'] != 'message' and @handlers.key? json['event'].to_sym
      rescue => e
        $logger.fatal e
      end
    end

    def on_socket_ping
      post('8::')
    end

    def on_chat_message(data)
      begin
        message = data['attrs']['text']
        user = @userlist[data['attrs']['name']]
        # return post(:msgType => :command, :command => :initquery) unless @initialized and !user.nil?
        @handlers[:message].each { |handler| handler.call(message, user) }
      rescue => e
        $logger.fatal e
      end
    end

    def ping_thr
      Thread.new {
        sleep 24
        post(:ping)
        ping_thr
      }
    end

    def on_chat_initial(data)
      ping_thr
      data['collections']['users']['models'].each do |user|
        attrs = user['attrs']
        @userlist[attrs['name']] = User.new(attrs['name'], attrs['isModerator'], attrs['isCanGiveChatMod'], attrs['isStaff'])
      end
      @initialized = true
    end

    def on_chat_join(data)
      if data['attrs']['name'] == @config['user'] and !@initialized
        post(:msgType => :command, :command => :initquery)
      end
      @userlist_mutex.synchronize do
        @userlist[data['attrs']['name']] = User.new(data['attrs']['name'], data['attrs']['isModerator'], data['attrs']['isCanGiveChatMod'], data['attrs']['isStaff'])
      end
    end

    def on_chat_part(data)
      @userlist_mutex.synchronize do
        @userlist.delete(data['attrs']['name'])
      end
    end

    def on_chat_logout(data)
      @userlist_mutex.synchronize do
        @userlist.delete(data['attrs']['name'])
      end
    end

    def send_msg(text)
      post(:msgType => :chat, :text => text)
    end

    def kick(user)
      post(:msgType => :command, :command => :kick, :userToKick => user)
    end

    def quit
      @running = false
      post(:msgType => :command, :command => :logout)
    end
  end
end
