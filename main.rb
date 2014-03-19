require_relative './client'
require_relative './plugins/auto_tube'
require_relative './plugins/holo'
$bot = Chatbot::Client.new
$bot.register_plugins(Chatbot::AutoTube, Chatbot::Holo)
$bot.run!