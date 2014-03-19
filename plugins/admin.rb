class Chatbot::Admin
  include Chatbot::Plugin

  match /^quit/, :method => :quit
  match /^plugins/, :method => :list_plugins

  def quit(captures, user)
    if user.is? :admin
      @client.send_msg "#{user.name}: Now exiting chat..."
      @client.running = false
    end
  end

  def list_plugins(captures, user)
  	if user.is? :mod
  	  @client.send_msg "#{user.name}, Currently loaded plugins are: " + @client.plugins.collect{|p| p.class.to_s}.join(', ')
  	end
  end

end