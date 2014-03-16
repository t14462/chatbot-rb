require 'httparty'
require 'media_wiki'
require 'logger'
require_relative './commands'
require_relative './util'

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG

class Chatbot
  include HTTParty
  include Commands


  USER_AGENT = 'sactage/chatbot-rb v0.0.1'
  CONFIG_FILE = 'config.yml'
  SOCKET_EVENTS = {'1::' => :on_socket_connect, '4:::' => :on_socket_message, '8::' => :on_socket_ping}


  attr_accessor :session, :clientid

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
    $logger.debug "get(): path=#{path}"
    path += "xhr-polling/#{@session}" unless @session.nil?
    res = self.class.get(path, :query => {:name => @config['user'], :key => @key, :roomId => @room, :t => Time.now.to_i}, :headers => @headers)
    $logger.debug '<- get()'
    return res
  end

  def post(body, path: '/socket.io/1/')
    $logger.debug '-> post()'
    $logger.debug "post(): body='#{body}'"
    path += "xhr-polling/#{@session}" unless @session.nil?
    $logger.debug "post(): path=#{path}"
    res = self.class.post(path, :query => {:name => @config['user'], :key => @key, :roomId => @room, :t => Time.now.to_i}, :body => body, :headers => @headers)
    $logger.debug '<- post()'
    return res
  end

  def run!
    while @running
      begin
        res = get
        puts res.body
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
      end
    end
    @threads.each {|thr| thr.join}
  end

  # BEGIN socket event methods
  def on_socket_connect

  end

  def on_socket_message(msg)
    $logger.debug '-> on_socket_message()'
    $logger.debug 'on_socket_message(): msg=' + msg
    json = JSON.parse(msg)
    json['data'] = JSON.parse(json['data'])
    $logger.debug 'on_socket_message(): json=' + json.to_s
    if json['event'] == 'chat:add' and not json['data']['id'].nil?
      json['event'] = 'message'
    end
    self.method("on_chat_#{json['event']}".to_sym).call(json['data']) # TODO make this less hacky
    $logger.debug '<- on_socket_message()'
  end

  def on_socket_ping
    $logger.debug '-> on_socket_ping()'
    post('2::')
    $logger.debug '<- on_socket_ping()'
  end
  # END socket event methods

  # BEGIN chat event methods
  def on_chat_message(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end

  def on_chat_initial(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end

  def on_chat_join(data)
    $logger.debug '-> ' + __method__
    $logger.debug 'on_chat_join(): data=' + data
    if data['attrs']['name'] == @config['user'] and @clientid.nil?
      @clientid = data['cid']
      post('3:::{"id":null,"cid":"' + @clientid + '","attrs":{"msgType":"command","command":"initquery"}}')
    end


  end

  def on_chat_part(data)
    puts '-----'
    puts __callee__
    puts data.inspect
  end

  def on_chat_kick(data)
    puts '-----'
    puts __callee__
    puts data.inspect
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
end

if __FILE__ == $0
  $bot = Chatbot.new
  $bot.run!
end