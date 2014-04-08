class Chatbot::Admin
  include Chatbot::Plugin

  match /^quit/, :method => :quit
  match /^plugins/, :method => :list_plugins
  match /^ignore (.*)/, :method => :ignore
  match /^unignore (.*)/, :method => :unignore

  def quit(captures, user)
    if user.is? :admin
      @client.send_msg "#{user.name}: Now exiting chat..."
      sleep 0.5
      @client.quit
    end
  end

  def list_plugins(captures, user)
  	if user.is? :mod
  	  @client.send_msg "#{user.name}, Currently loaded plugins are: " + @client.plugins.collect{|p| p.class.to_s}.join(', ')
  	end
  end

  def ignore(captures, user)
    if user.is? :mod
      target = captures[1]
      if @client.userlist.key? target
        @client.userlist[target].ignore
      else
        User.new(target).ignore
      end
      @client.send_msg "#{user.name}: I'll now ignore all messages from #{target}."
    end
  end

  def unignore(captures, user)
    if user.is? :mod
      target = captures[1]
      if @client.userlist.key? target
        @client.userlist[target].unignore
      else
        User.new(target).unignore
      end
      @client.send_msg "#{user.name}: I'll now listen to all messages from #{target}."
    end
  end


end