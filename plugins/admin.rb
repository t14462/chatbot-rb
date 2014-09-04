class Chatbot::Admin
  include Chatbot::Plugin

  match /^quit/, :method => :quit
  match /^plugins/, :method => :list_plugins
  match /^ignore (.*)/, :method => :ignore
  match /^unignore (.*)/, :method => :unignore
  match /^commands/, :method => :get_commands
  match /^source|^src|^git(?:hub)?/, :method => :source

  def quit(user)
    if user.is? :admin
      @client.send_msg "#{user.name}: Now exiting chat..."
      sleep 0.5
      @client.quit
    end
  end

  def get_commands(user)
    return if @client.config['wiki'].eql? 'central'
    commands = @client.plugins.collect {|plugin| plugin.class.matchers}.collect {|matchers| matchers.select {|matcher| matcher.use_prefix}}.flatten
    @client.send_msg(user.name + ', all defined commands are: ' + commands.collect{|m|m.pattern.to_s.gsub('(?-mix:^', m.prefix).gsub(/\$?\)$/, '')}.join(', ') + '. (Confused? Learn regex!)')
  end

  def list_plugins(user)
  	if user.is? :mod
  	  @client.send_msg "#{user.name}, Currently loaded plugins are: " + @client.plugins.collect{|p| p.class.to_s}.join(', ')
  	end
  end

  def ignore(user, target)
    if user.is? :mod
      if @client.userlist.key? target
        @client.userlist[target].ignore
      else
        User.new(target).ignore
      end
      @client.send_msg "#{user.name}: I'll now ignore all messages from #{target}."
    end
  end

  def unignore(user, target)
    if user.is? :mod
      if @client.userlist.key? target
        @client.userlist[target].unignore
      else
        User.new(target).unignore
      end
      @client.send_msg "#{user.name}: I'll now listen to all messages from #{target}."
    end
  end

  def source(user)
    @client.send_msg "#{user.name}: My source code can be seen at https://github.com/sactage/chatbot-rb - feel free to contribute!"
  end

end