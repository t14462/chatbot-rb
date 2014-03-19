class Chatbot::Admin
  include Chatbot::Plugin

  match /^quit/, :method => :quit

  def quit(captures, user)
    if user.is? :admin
      @client.send_msg "#{user.name}: Now exiting chat..."
      @client.running = false
    end
  end
end