require_relative './client'
require_relative './plugins/admin' # You should generally always require this, as it includes commands like !quit/!plugins

$bot = Chatbot::Client.new
$bot.register_plugins(Chatbot::Admin) # Register the plugins with our bot
$bot.run! # Run the bot!
