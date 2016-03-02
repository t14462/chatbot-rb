require_relative '../plugin'

class RUTES
        include Chatbot::Plugin

        match /^Kixtech.*/, :use_prefix => false, :method => :sempai
	match /^team|^команда/, :method => :team

        def sempai(user)
            rndm = Random.new
            notsempai = ["Oh. Hi. So. How are you holding up? BECAUSE I'M A POTATO.","I knows nothing","Nyeeeeees...","ey b0ss, ey b0ss","Stop right there, you criminal scum!","I'm tired, gotta go.","I have an arrow in my knee. DAMN YOU ADVENTURE!","I'm not safe for work. Literally, I can turn off. I don't know why. I'm just a machine without feels.","#{user.name}, you're not my sempai... >_>"]
                case user.name
                when "KORNiUX", "Кистрел Дикин"
                    @client.send_msg "#{user.name} notice me... *^__^*"
                when "Ииши", "Plizirim", "Lelu02"
                    @client.send_msg "Purr, purr, purrrrrr, #{user.name} :3"
                else
                    @client.send_msg notsempai[rndm.rand(0..notsempai.count)]
                end
        end
	
	def team(user)
		@client.send_msg "#{user.name}, подробней о [[Project:Команда вики|команде вики]]."
	end
	
end
