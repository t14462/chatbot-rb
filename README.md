chatbot-rb
==========

A plugin-based bot framework in Ruby for [Wikia's](http://wikia.com/) [Special:Chat](https://github.com/Wikia/app/tree/dev/extensions/wikia/Chat2) extension.

Installation
============
To run a bot using this framework, Ruby 2.1+ is expected. I develop on the latest stable version (2.1.3 at the time of writing), and generally will not accommodate any problems that are only affect older versions of Ruby.

*Note*: The framework does not currently work on Windows with Ruby 2.1.3 due to an issue with `mediawiki-gateway` and the `ffi` gem.

This framework requires [HTTParty](https://rubygems.org/gems/httparty) and [mediawiki-gateway](https://rubygems.org/gems/mediawiki-gateway). You can install them both with `[sudo] gem install httparty mediawiki-gateway`.

Some of the included plugins may also have dependencies - they will be listed in the plugins section of this readme.

Running
=======
Please follow the format outlined in `main.sample.rb` and `config.sample.yml` to setup a working bot. The Wikia account used to connect to chat will not *need* bot rights, but if you're using the `wiki_log` plugin or making edits on-wiki it will be useful.

Plugins
=======
The plugin system for this bot is **heavily** inspired by that of [Cinch](https://github.com/cinchrb/cinch), albeit very watered down.

The following plugins are included in the repository. You may use them if you wish or create your own.

Commands followed by `[M]` require chat moderator rights (or above), and those followed by `[A]` require administrator rights.

## `admin`
Used for administration of the bot.

**Included commands:**
- **!quit** `[A]`: Makes the bot quit from chat.
- **!plugins**: Lists all of the plugins currently loaded.
- **!ignore <user>** `[M]`: Adds the specified user to the ignore list.
- **!unignore <user>** `[M]`: Removes the specified user from the ignore list.
- **!commands**: Lists all of the commands registered with the bot. Note that they are displayed as the regular expression patterns passed to `match` in the plugin file.
- **!source**, **!src**, **!git**, **!github**: Provides a link to the master repository for the bot framework.

