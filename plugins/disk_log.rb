require_relative '../util'

class Chatbot::DiskLog
  include Chatbot::Plugin

  match /.*/, :method => :log_message
  listen_to :join, :log_join
  listen_to :part, :log_part
  listen_to :kick, :log_kick
  listen_to :ban, :log_ban

  def initialize(bot)
    super(bot)
    @logfile_mutex = Mutex.new
  end

  def log_message(captures, user)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write(Util::ts + " <#{user.log_name}> #{captures[0]}")}
    end
  end

  def log_join(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write(Util::ts + " -!- #{data['attrs']['name']} has joined #Special:Chat")}
    end
  end

  def log_part(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write(Util::ts + " -!- #{data['attrs']['name']} has left [Leaving]")}
    end
  end

  def log_kick(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write(Util::ts + " -!- #{data['attrs']['kickedUserName']} was kicked from #Special:Chat by #{data['attrs']['moderatorName']} [KICK]")}
    end
  end

  def log_ban(data)
    @logfile_mutex.synchronize do
      File.open("chat.log", 'a') {|f| f.write(Util::ts + " -!- #{data['attrs']['kickedUserName']} was kicked from #Special:Chat by #{data['attrs']['moderatorName']} [BAN]")}
    end
  end

end