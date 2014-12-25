require_relative '../plugin'
require 'mysql2'

class SQLLog
  include Chatbot::Plugin
  match /(.*)/, :method => :log_message, :use_prefix => false
  listen_to :join, :log_join
  listen_to :part, :log_part
  listen_to :kick, :log_kick
  listen_to :ban, :log_ban

  MESSAGE_INSERT = "INSERT INTO logs (timestamp, user, log_line) VALUES(NOW(), '%s', '%s')"
  ME_INSERT      = "INSERT INTO logs (timestamp, user, log_line, event) VALUES(NOW(), '%s', '%s', 'ME')"
  KICK_INSERT    = "INSERT INTO logs (timestamp, user, target, event) VALUES(NOW(), '%s', '%s', 'KICK')"
  BAN_INSERT     = 'INSERT INTO logs (timestamp, user, target, ban_reason, event, ban_time) '\
                  "VALUES(NOW(), '%s', '%s', '%s', '%s', %d)"
  # @param [Chatbot::Client] bot
  def initialize(bot)
    super(bot)
    @db = Mysql2::Client.new(:host      => @client.config[:sqlhost],
                             :username  => @client.config[:sqluser],
                             :password  => @client.config[:sqlpass],
                             :database  => @client.config[:sqldb],
                             :reconnect => true)
  end

  # @param [User] user
  # @param [String] message
  def log_message(user, message)
    message.split(/\n/).each do |line|
      if /^\/me/.match(line) and message.start_with? '/me'
        @db.query(ME_INSERT % [user.name, line.gsub(/^\/me /, '')].map(&@db.method(:escape)))
      elsif message.start_with? '/me'
        @db.query(ME_INSERT % [user.name, line.gsub(/^\/me /, '')].map(&@db.method(:escape)))
      else
        @db.query(MESSAGE_INSERT % [user.name, line].map(&@db.method(:escape)))
      end
    end
  end

  # @param [Hash] data
  def log_join(data)
    @db.query("INSERT INTO logs (timestamp, user, event) VALUES(NOW(), '#{@db.escape(data['attrs']['name'])}', 'JOIN')")
  end

  # @param [Hash] data
  def log_part(data)
    @db.query("INSERT INTO logs (timestamp, user, event) VALUES(NOW(), '#{@db.escape(data['attrs']['name'])}', 'PART')")
  end

  # @param [Hash] data
  def log_kick(data)
    @db.query(KICK_INSERT % [data['attrs']['moderatorName'], data['attrs']['kickedUserName']].map(&@db.method(:escape)))
  end

  # @param [Hash] data
  def log_ban(data)
    time = data['attrs']['time'] == '31536000000' ? -1 : data['attrs']['time'].to_i
    @db.query(BAN_INSERT % ([data['attrs']['moderatorName'],
                             data['attrs']['kickedUserName'],
                             data['attrs']['reason'],
                             time == 0 ? 'UNBAN' : 'BAN'].map(&@db.method(:escape)) + [time]))
  end

end