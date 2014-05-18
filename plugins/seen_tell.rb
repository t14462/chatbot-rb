class SeenTell
  include Chatbot::Plugin

  match /^seenon/, :method => :enable_seen
  match /^seenoff/, :method => :disable_seen
  match /^tell ([^ ]+) (.+)/, :method => :tell
  match /^seen (.*)/, :method => :seen_user
  match /^tellon ?(:.+)?/, :method => :enable_tell
  match /^telloff ?(:.+)?/, :method => :disable_tell
  match /.*/, :method => :update_user, :use_prefix => false
  listen_to :join, :update_user

  def initialize(bot)
    super(bot)
    if File.exists? 'tells.yml'
      @tells = YAML::load_file 'tells.yml'
    else
      File.open('tells.yml', 'w+') {|f| f.write({}.to_yaml)}
      @tells = {}
    end
    if File.exists? 'seen.yml'
      @seen = YAML::load_file 'seen.yml'
    else
      File.open('seen.yml', 'w+') {|f| f.write({}.to_yaml)}
      @seen = {}
    end
    @tell_mutex = Mutex.new
    @allow_seen = true
    @allow_tell = true
  end

  def enable_tell(captures, user)
    if user.is? :admin and !@allow_tell
      @allow_tell = true
      @client.send_msg user.name + ': !tell is now enabled'
    end
  end

  def disable_tell(captures, user)
    if user.is? :mod and @allow_tell
      @allow_tell = false
      @client.send_msg user.name + ': !tell is now disabled'
    end
  end

  def tell(captures, user)
    return unless @allow_tell
    target = captures[1].gsub(/_/, ' ')
    message = captures[2]
    if target.downcase.eql? user.name.downcase
      return @client.send_msg user.name + ': You can\'t !tell yourself something!'
    elsif target.downcase.eql? @client.config['user'].downcase
      return @client.send_msg user.name + ': Thanks for the message <3'
    end
    @tell_mutex.synchronize do
      if @tells.key? target.downcase
        @tells[target.downcase][user.name] = message
      else
        @tells[target.downcase] = {user.name => message}
      end
      File.open('tells.yml', File::WRONLY) {|f| f.write(@tells.to_yaml)}
      @client.send_msg "#{user.name}: I'll tell #{target} that the next time I see them."
    end
  end

  def seen_user(captures, user)
    return unless @allow_seen
    if @seen.key? captures[1].downcase
      @client.send_msg "#{user.name}: I last saw #{captures[1]} #{get_hms(Time.now.to_i - @seen[captures[1].downcase])}"
    else
      @client.send_msg "#{user.name}: I haven't seen #{captures[1]}"
    end
  end

  def enable_seen(captures, user)
    if user.is? :mod and !@allow_seen
      @allow_seen = true
      @client.send_msg "#{user.name}: !seen enabled"
    end
  end

  def disable_seen(captures, user)
    if user.is? :mod and @allow_seen
      @allow_seen = false
      @client.send_msg "#{user.name}: !seen disabled"
    end
  end

  def update_user(data, *args)
    if args.size > 0 # Message
      user = args[0]
      if @tells.key? user.name.downcase
        @tell_mutex.synchronize do
          @tells[user.name.downcase].each do |k, v|
            @client.send_msg "#{user.name}, #{k} told you: #{v}"
          end
          @tells[user.name.downcase] = {}
          File.open('tells.yml', 'w+') {|f| f.write(@tells.to_yaml)}
        end
      end
    else
      user = @client.userlist[data['attrs']['name']]
    end
    @seen[user.name.downcase] = Time.now.to_i
    File.open('seen.yml', File::WRONLY) {|f| f.write(@seen.to_yaml)}
  end

  def get_hms(ts)
    weeks = ts / 604800
    ts %= 604800
    days = ts / 86400
    ts %= 86400
    hours = ts / 3600
    ts %= 3600
    minutes = ts / 60
    ts %= 60
    ret = ''
    ret += "#{weeks} week#{weeks > 1 ? 's' : ''}, " if weeks > 0
    ret += "#{days} day#{days > 1 ? 's' : ''}, " if days > 0
    ret += "#{hours} hour#{hours > 1 ? 's' : ''}, " if hours > 0
    ret += "#{minutes} minute#{minutes > 1 ? 's' : ''}, " if minutes > 0
    ret.gsub(/, $/, " and ") + "#{ts} second#{ts != 1 ? 's' : ''} ago."

  end
end