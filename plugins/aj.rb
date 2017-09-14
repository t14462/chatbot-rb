require_relative '../plugin'

class Chatbot::Filters
  include Chatbot::Plugin

  match /^!.*|^Kixtech.*|^team|^команда/, :method => :abusecontrol, :use_prefix => false # /
  match /(.*)/, :method => :filtercontrol, :use_prefix => false
  
  
  def initialize(bot)
    super(bot)
	cleanstart
	capsstart
  end
  
  def cleanstart
    Thread.new {
	  @abuse = {}
	  sleep 24
	  cleanstart
    }
  end
    def capsstart
    Thread.new {
	  @caps = {}
	  sleep 150
	  capsstart
    }
  end
  
  def abusecontrol(user)
    #if !$data['config']['modules']['abuse'] or user.is?(:mod) then
    if user.is?(:mod) then
	  return
	end
	if @abuse.key?(user.name) then
	  @abuse[user.name] = @abuse[user.name] + 1
	  if @abuse[user.name] > 9 then
	    @client.send_msg "#{user.name},\nБот на кота обиделся\nи 9 жизней исчерпал..."
	    @abuse[user.name] = 0
		if @client.userlist.key? user.name
          @client.userlist[user.name].ignore
        else
          User.new(user.name).ignore
        end
	  end
	else
	  @abuse[user.name] = 1
	end
  end
  
  def filtercontrol(user, message)
	s = message.size
	if s > 88 then
	  message = message.gsub(/(%[A-Za-z0-9]{2}|[^A-ZА-Яa-zа-я0-9_])/, '')
	  s = message.size
	  u = message.count("A-ZА-Я")
	  res = (u.to_f / s.to_f) * 100
	  if res >= 72 then
		@client.send_msg "#{user.name}, [[Project:Правила_чата#Злоупотребление форматированием|КАПС]] #{res.floor}%"
		if !@caps.key?(user.name) then
		  @caps[user.name] = 1
		else
		  @caps[user.name] = @caps[user.name] + 1
		  if @caps[user.name] > 3 then
		    @caps[user.name] = 0
		    #if $data['config']['modules']['moder'] then
			  if user.is? :mod then
			    #@client.send_msg "#{user.name}, Капсь в личку."
			    @client.send_msg "Капсь в личку, RETARD!!!"
			  else
		        #@client.send_msg "#{user.name}, использование капса больше трёх раз — это уже слишком!"
		        @client.send_msg "Использование капса больше трёх раз — это уже слишком!"
			    @client.kick "#{user.name}"
			  end
		    #end 
		  end
		end
	  end
	end
  end
end
