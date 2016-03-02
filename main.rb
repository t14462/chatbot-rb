require_relative './client'
require_relative './plugins/admin'
require_relative './plugins/wiki_log'
$bot = Chatbot::Client.new
$bot.register_plugins(Chatbot::Admin, WikiLog)
$bot.run!
