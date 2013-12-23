require_relative 'media_wiki'

module ChatBot
  class Tests
    def initialize
      @config = YAML.load(File.new('test_config.yaml'))
    end

    def login_test

      wiki = MediaWiki.new @config['wiki']
      begin
        wiki.log_in(@config['user'], @config['password'])
        if wiki.logged_in?
          puts "Logged in as #{@config['user']}!"
        end
      rescue MediaWiki::LoginError => e
        puts "Error logging in!"
        p e
      ensure
        wiki.log_out
        puts "Logged out!"
      end

    end
  end
end

test = ChatBot::Tests.new
test.login_test