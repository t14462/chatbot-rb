require_relative 'client'
require_relative 'plugins/disk_log'
require_relative 'plugins/admin'
require_relative 'plugins/wiki_log'
require_relative 'plugins/rutes'
$bot = Chatbot::Client.new
$bot.register_plugins(Chatbot::Admin, Chatbot::DiskLog, WikiLog, RUTES)
$bot.run!
