require_relative '../util'

class Chatbot::DiskLog
  include Chatbot::Plugin

  match /.*/, :method => :log_message, :use_prefix => false
  listen_to :join, :log_join
  listen_to :part, :log_part
  listen_to :kick, :log_kick
  listen_to :ban, :log_ban

  def initialize(bot)
    super(bot)
    @logfile_mutex = Mutex.new
  end

  def log_message(user, message)
    @logfile_mutex.synchronize do
      message.split(/\n/).each do |line|
        if /^\/me/.match line
          File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " * #{user.log_name} #{line.gsub(/\/me /, '')}")}
        else
          File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " <#{user.log_name}> #{line}")}
        end
      end
    end
  end

  def log_join(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " -!- #{data['attrs']['name']} [~chat@wikia/#{data['attrs']['name'].gsub(/ /, '-')}] has joined #Special:Chat")}
    end
  end

  def log_part(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " -!- #{data['attrs']['name']} [~chat@wikia/#{data['attrs']['name'].gsub(/ /, '-')}] has left #Special:Chat [Leaving]")}
    end
  end

  def log_kick(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " -!- #{data['attrs']['kickedUserName']} was kicked from #Special:Chat by #{data['attrs']['moderatorName']} [KICK]")}
    end
  end

  def log_ban(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write("\n" + Util::ts + " -!- #{data['attrs']['kickedUserName']} was kicked from #Special:Chat by #{data['attrs']['moderatorName']} [BAN]")}
    end
  end

end