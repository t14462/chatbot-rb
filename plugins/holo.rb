class Chatbot::Holo
  include Chatbot::Plugin
  match /^Holo, I love you/, :use_prefix => false
  match /^Holo, kill/, :use_prefix => false, :method => :poor_cod4
  def execute(captures, user)
    if user.name.eql? 'Sactage'
      @client.send_msg '/me snuggles up to Sactage'
      @client.send_msg 'I love you too <3'
    end
  end

  def poor_cod4(captures, user)
    if user.name.eql? 'Sactage'
      @client.send_msg '/me breaks Callofduty4\'s neck'
      @client.send_msg 'I love you, Sactage <3'
    end
  end
end