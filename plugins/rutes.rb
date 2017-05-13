require_relative '../plugin'

class RUTES
    include Chatbot::Plugin

    match /^Kixtech.*/, :use_prefix => false, :method => :quotes
	match /^gag$/, :method => :gag
	match /^dev$/, :method => :dev
	match /^ungag$/, :method => :ungag
	match /^\!aq (.*)$/, :use_prefix => false, :method => :newquote
	$gag = 0
	
    def quotes(user)
	    if $gag == 0
        	rndm = Random.new
		    if File.file?("./quotes/#{user.name}.txt")
		        f = File.open("./quotes/#{user.name}.txt", "r")
		    else
		        f = File.open("./quotes/main.txt","r")
		    end
	        lines = f.read.split("\n")
	        @client.send_msg lines[rndm.rand(0..lines.count)]
	        f.close
	    end
    end
	
	def newquote(user, message)
	    if $gag == 0
		if File.file?("./quotes/#{user.name}.txt")
		    f = File.open("./quotes/#{user.name}.txt","a")
		else
		    f = File.new("./quotes/#{user.name}.txt", "w")
		    # TODO: REPLACE USER FOR CHOWN FOR QUOTE MODERATION VIA SSH|FTP|ETC
		    FileUtils.chown 'kix', 'chatbot', "./quotes/#{user.name}.txt", :verbose => true
		    FileUtils.chmod 0765, "./quotes/#{user.name}.txt", :verbose => true
		end
		@client.send_msg "Ваша фраза была добавлена в цитаты."
		f.puts("#{message}")
		f.close
	    end
	end

	
	def dev(user)
		@client.send_msg "Разработчики бота: \n Кодеры: [[User:Кистред Дикин|Set440 (t14462)]] / [[User:KORNiUX|KORN1UX (kix)]] \n Тестеры: [[User:TarrakoT|tarr]] \n All hail to [[User:Sactage|Sactage]]\n\nПодробней в команде !git"
	end

	def gag(user)
		if $gag == 0
		    if user.is? :mod
			    $gag = 1
			    @client.send_msg "Режим обратной связи отключен. Для включения обратитесь к модератору."
		    end
		end
	end
	
	def ungag(user)
		if $gag == 1
		    if user.is? :mod
		    	$gag = 0
		    	@client.send_msg "Режим обратной связи включен. Что я пропустил?"
		    end
		end
	end

end