class SeenTell
  include Chatbot::Plugin

  #match /^seenon/, :method => :enable_seen
  #match /^seenoff/, :method => :disable_seen
  match /^tell ([^ ]+) (.+)/, :method => :tell
  match /^seen (.*)/, :method => :seen
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

    @allow_seen = true
  end

  def tell(captures, user)
    target = captures[1].gsub(/_/, ' ')
    message = captures[2]
    if target.downcase.eql? user.name.downcase
      @client.send_msg user.name + ': You can\'t !tell yourself something!'
    elsif target.downcase.eql? @client.config['user'].downcase
      @client.send_msg user.name + ': Thanks for the message <3'
    end
    if @tells.key? target.downcase
      @tells[target.downcase][user.name] = message
    else
      @tells[target.downcase] = {user.name => message}
    end
    File.open('tells.yml', File::WRONLY) {|f| f.write(@tells.to_yaml)}
    @client.send_msg "#{user.name}: I'll tell #{target} that the next time I see them."
  end

  def seen(captures, user)
    return @client.send_msg "#{user.name}: Sorry, !seen is currently down for maintenance right now :( bother Sactage until it's fixed!"
    if @seen.key? captures[1].downcase
      @client.send_msg "#{user.name}: I last saw #{captures[1]} #{Time.now.to_i - @seen[@captures[1].downcase]} seconds ago"
    else
      @client.send_msg "#{user.name}: I haven't seen #{captures[1]}"
    end
  end

  def update_user(data, *args)
    if args.size > 0 # Message
      user = args[0]
    else
      user = @client.userlist[data['attrs']['name']]
    end
    @seen[user.name.downcase] = Time.now.to_i
    File.open('seen.yml', File::WRONLY) {|f| f.write(@seen.to_yaml)}
    if @tells.key? user.name.downcase
      @tells[user.name.downcase].each do |k, v|
        @client.send_msg "#{user.name}, #{k} told you: #{v}"
      end
      @tells[user.name.downcase] = {}
      File.open('tells.yml', File::WRONLY) {|f| f.write(@tells.to_yaml)}
    end
  end
end