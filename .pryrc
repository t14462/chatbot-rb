require_relative 'client'
require_relative 'plugin'
require_relative 'events'
require_relative 'util'

def load_plugin(plugin_name)
  require_relative './plugins/' + plugin_name
end

