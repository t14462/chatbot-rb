require_relative 'client'
require_relative 'plugins/disk_log' # Require all of the plugins we want here
require_relative 'plugins/admin' # You should generally always require this, as it includes commands like !quit/!plugins

$bot = Chatbot::Client.new
$bot.register_plugins(Chatbot::Admin, Chatbot::DiskLog) # Register the plugins with our bot
$bot.run! # Run the bot!
