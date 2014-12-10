require_relative '../plugin'

class Chatbot::Holo
  include Chatbot::Plugin

  match /^Holo, I love you/, :use_prefix => false
  match /^Holo, kill/, :use_prefix => false, :method => :poor_cod4
  match /^\/me gives Holo an apple/, :use_prefix => false, :method => :apple

  # @param [User] user
  def execute(user)
    if user.name.eql? 'Sactage'
      @client.send_msg '/me snuggles up to Sactage'
      @client.send_msg 'I love you too <3'
    else
      @client.send_msg "#{user.name}: Holo the Wise Wolf does not associate with such filth"
    end
  end

  # @param [User] user
  def poor_cod4(user)
    if user.name.eql? 'Sactage'
      @client.send_msg '/me breaks Callofduty4\'s neck'
      @client.send_msg 'I love you, Sactage <3'
    end
  end

  # @param [User] user
  def apple(user)
    if user.name.eql? 'Sactage'
      @client.send_msg '/me happily chomps on the apple'
      @client.send_msg 'Thanks sweetie! <3'
    else
      @client.send_msg "/me throws the apple back at #{user.name}, hitting them square in the face"
    end
  end
end