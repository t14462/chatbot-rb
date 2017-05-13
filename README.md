rutes-chatbot-rb
================

A plugin-based bot framework in Ruby for [Wikia's](http://wikia.com/) [Special:Chat](https://github.com/Wikia/app/tree/dev/extensions/wikia/Chat2) extension.

Forked from [Sactage's](https://github.com/sactage) Ruby chatbot.

Installation
============
To run a bot using this framework, Ruby 2.1+ is expected. I develop on the latest stable version (2.1.3 at the time of writing), and generally will not accommodate any problems that are only affect older versions of Ruby.

*Note*: The framework does not currently work on Windows with Ruby 2.1.3 due to an issue with `mediawiki-gateway` and the `ffi` gem.

This framework requires [HTTParty](https://rubygems.org/gems/httparty) and [mediawiki-gateway](https://rubygems.org/gems/mediawiki-gateway). You can install them both with `[sudo] gem install httparty mediawiki-gateway`.

Configure
=========
- Please follow the format outlined in `main.sample.rb` and `config.sample.yml` to setup a working bot. The Wikia account used to connect to chat will not *need* bot rights, but if you're using a logging plugin or otherwise editing it will be useful.
- Put it to /wiki/Module:S44 page on your wiki content of *Wikia-Module-S44.lua* file.
- Configure *rutes.service* file (like working directory).

Running
=======
Running via *ruby main.rb*, *rutes.service* or *bot.sh* (in tmux for example).


