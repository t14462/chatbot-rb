require 'httparty'
require 'media_wiki'
require 'logger'
require_relative './commands'
require_relative './util'
require_relative 'plugins/auto_tube'

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

class Chatbot
  include HTTParty


  USER_AGENT = 'sactage/chatbot-rb v0.0.1'
  CONFIG_FILE = 'config.yml'

  SOCKET_EVENTS = {'1::' => :on_socket_connect, '4:::' => :on_socket_message, '8::' => :on_socket_ping}


  attr_accessor :session, :clientid, :handlers, :config

  def initialize
    unless File.exists? CONFIG_FILE
      $logger.fatal "Config: #{CONFIG_FILE} not found!"
      exit
    end

    @config = YAML::load_file CONFIG_FILE
    @api = MediaWiki::Gateway.new "http://#{@config['wiki']}.wikia.com/api.php"
    @api.login(@config['user'], @config['password'])
    @headers = {'User-Agent' => USER_AGENT, 'Cookie' => @api.cookies.map {|k,v| "#{k}=#{v};" }.join(' '), 'Content-type' => 'text/plain;charset=UTF-8'}
    @logfile_mutex = Mutex.new
    @logfile = File.open('chat.log', 'a')
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
        :ban => []
    }
  end

  def register_plugins(*plugins)
    plugins.each do |plugin|
      @plugins << plugin.new(self)
      @plugins.last.register
    end

  end
  def fetch_chat_info
    res = HTTParty.get("http://#{@config['wiki']}.wikia.com/wikia.php?controller=Chat&format=json", :headers => @headers)
    data = JSON.parse(res.body, :symbolize_names => true)
    @key = data[:chatkey]
    @server = data[:nodeHostname]
    @room = data[:roomId]
    @mod = data[:isChatMod]
    self.class.base_uri "http://#{@server}/"
    @session = get.body.match(/\d+/)[0] # *probably* should check for nil here and rescue, but I'm too lazy
  end

  def get(path: '/socket.io/1/')
    $logger.debug '-> get()'
    path += "xhr-polling/#{@session}" unless @session.nil?
    $logger.debug "get(): path=#{path}"
    res = self.class.get(path, :query => {:name => @config['user'], :key => @key, :roomId => @room, :t => Time.now.to_i}, :headers => @headers)
    $logger.debug '<- get()'
    res
  end

  def post(body, path: '/socket.io/1/')
    $logger.debug '-> post()'
    $logger.debug "post(): body='#{body}'"
    path += "xhr-polling/#{@session}" unless @session.nil?
    $logger.debug "post(): path=#{path}"
    res = self.class.post(path, :query => {:name => @config['user'], :key => @key, :roomId => @room, :t => Time.now.to_i}, :body => body, :headers => @headers)
    $logger.debug '<- post()'
    res
  end

  def run!
    $logger.debug '-> run!()'
    while @running
      begin
        $logger.debug 'run!(): res = get()'
        res = get
        body = res.body
        if body.include? "\xef\xbf\xbd"
          body.split(/\xef\xbf\xbd/).each do |part|
            next unless part.size > 10
            event = part.match(/\d:::?/)[0]
            data = part.sub(event, '')
            @threads << Thread.new(event, data) {
              case event
                when '1::'
                 on_socket_connect
                when '8::'
                  on_socket_ping
                when '4:::'
                  on_socket_message(data)
                else
                  1
              end
            }
          end
        else
          event = body.match(/\d:::?/)[0]
          data = body.sub(event, '')
          $logger.debug 'run!(): event=' + event
          @threads << Thread.new(event, data) {
            case event
              when '1::'
                on_socket_connect
              when '8::'
                on_socket_ping
              when '4:::'
                on_socket_message(data)
              else
                1
            end
          }
        end
      rescue Net::ReadTimeout
      # TODO Handle *all* the errors!
        $logger.warn 'Net::ReadTimeout in run!()'
      end
    end
    @threads.each {|thr| thr.join}
  end

  # BEGIN socket event methods
  def on_socket_connect

  end

  def on_socket_message(msg)
    begin
      $logger.debug '-> on_socket_message()'
      $logger.debug 'on_socket_message(): msg=' + msg
      json = JSON.parse(msg)
      json['data'] = JSON.parse(json['data'])
      $logger.debug 'on_socket_message(): json=' + json.to_s
      if json['event'] == 'chat:add' and not json['data']['id'].nil?
        json['event'] = 'message'
      end
      $logger.info 'on_socket_message(): ' + ("on_chat_#{json['event']}" == 'on_chat_join').to_s
      self.method("on_chat_#{json['event']}".to_sym).call(json['data']) # TODO make this less hacky
      $logger.info 'on_socket_message(): event ==> ' + json['event']
      #self.on_chat_join(json['data'])
      $logger.debug '<- on_socket_message()'
    rescue => e
      $logger.fatal e
    end
  end

  def on_socket_ping
    $logger.debug '-> on_socket_ping()'
    post('8::')
    $logger.debug '<- on_socket_ping()'
  end
  # END socket event methods

  # BEGIN chat event methods
  def on_chat_message(data)
    $logger.debug '-> on_chat_message()'
    begin
      message = data['attrs']['text']
      puts @userlist.inspect
      user = @userlist[data['attrs']['name']]
      $logger.info "<#{user.name}> #{message}"
      @logfile_mutex.synchronize do
        if /^\* #{user.name}/.match(message)
          @logfile.write(Util::ts + " %s" % message.sub(user.name, user.log_name))
        else
          @logfile.write(Util::ts + " <#{user.log_name}> #{message}")
        end
        if message.include? "\n"
          message.split("\n").each do |m|
            @logfile.write(Util::ts + " <#{user.log_name}> #{m}")
          end
        end
      end

      return if user.ignored?
      @handlers[:message].each {|handler| handler.call(message, user)}
    rescue => e
      $logger.fatal e
    end
    

  end

  def on_chat_initial(data)
    data['collections']['users']['models'].each do |user|
      attrs = user['attrs']
      @userlist[attrs['name']] = User.new(attrs['name'], attrs['isModerator'], attrs['isCanGiveChatMod'], attrs['isStaff'])
    end
  end


  def on_chat_join(data)
    $logger.debug '-> on_chat_join()'
    $logger.debug 'on_chat_join(): data=' + data.to_s
    if data['attrs']['name'] == @config['user'] and @clientid.nil?
      @clientid = data['cid']
      post('3:::{"id":null,"cid":"' + @clientid + '","attrs":{"msgType":"command","command":"initquery"}}')
    end
    $logger.info "#{data['attrs']['name']} joined"
    @userlist_mutex.synchronize do
      @userlist[data['attrs']['name']] = User.new(data['attrs']['name'], data['attrs']['isModerator'], data['attrs']['isCanGiveChatMod'], data['attrs']['isStaff'])
    end
    $logger.debug '<- on_chat_join()'
  end

  def on_chat_part(data)
    $logger.debug '-> on_chat_part()'
    $logger.info "#{data['attrs']['name']} left the chat"
    @userlist_mutex.synchronize do
      @userlist.delete(data['attrs']['name'])
    end
    $logger.debug '<- on_chat_part()'
  end

  def on_chat_kick(data)
    $logger.debug '-> on_chat_kick()'
  end

  def on_chat_ban(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end

  def on_chat_logout(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end

  def on_chat_update_user(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end
  # END chat event methods

  def send_msg(text)
    post('5:::{"name":"message","args":["{\"attrs\":{\"msgType\":\"chat\",\"text\":\"' + text.gsub('"', '\\"') + '\"}}"]}')
  end
end

if __FILE__ == $0
  $bot = Chatbot.new
  $bot.register_plugins(AutoTube)
  $bot.run!
end