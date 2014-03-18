class WikiLog
  include Plugins::Plugin
  match /^updatelogs$/, :method => :update_logs_command
  match /^logs$/, :method => :logs_command
  match /^updated$/, :method => :updated_command

  listen_to :join, :on_join
  listen_to :message, :on_message
  listen_to :part, :on_part
  listen_to :kick, :on_kick
  listen_to :ban, :on_ban

  attr_accessor :log_thread

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
end