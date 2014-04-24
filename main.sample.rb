require_relative './client'
require_relative './plugins/auto_tube' # Require all of the plugins we want here
require_relative './plugins/holo'

$bot = Chatbot::Client.new
$bot.register_plugins(ChatBot::AutoTube, ChatBot::Holo) # Register the plugins with our bot
$bot.run! # Run the bot!