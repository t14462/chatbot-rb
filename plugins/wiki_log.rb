class WikiLog
  include Chatbot::Plugin
  match /^updatelogs$/, :method => :update_logs_command
  match /^logs$/, :method => :logs_command
  match /^updated$/, :method => :updated_command

  listen_to :join, :on_join
  listen_to :message, :on_message
  listen_to :part, :on_part
  listen_to :kick, :on_kick
  listen_to :ban, :on_ban

  attr_accessor :log_thread, :buffer, :buffer_mutex
  def initialize(bot)
    super(bot)
    @buffer = ''
    @buffer_mutex = Mutex.new
    @log_thread = make_thread
    @last_log = nil
  end

  def make_thread
    thr = Thread.new {
      sleep 3600
      update_logs
    }
    @client.threads << thr
    thr
  end

  def update_logs

  end

  def update_logs_command(captures, user)
    if user.is? :mod
      @log_thread.kill
      @buffer_mutex.synchronize do
        lines = @buffer.scan(/\n/).size
        update_logs
        @log_thread = make_thread
        @client.send_msg "#{user.name}: [[Project:Chat/Logs|Logs]] updated (added ~#{lines} to log page)."
      end
    end
  end

  def logs_command(captures, user)

  end

  def updated_command(captures, user)
    if @last_log.nil?
      @client.send_msg "#{user.name}: I haven't updated the logs since I joined here. There are currently ~#{@buffer.scan(/\n/).size} lines in the log buffer."
    else
      @client.send_msg "#{user.name}: I last updated the logs #{Time.now.utc.to_i - @last_log.to_i} seconds ago. There are currently ~#{@buffer.scan(/\n/).size} lines in the log buffer."
    end
  end
end
