class BanNotify
  include Chatbot::Plugin

  listen_to :ban, :execute

  BAN_TEMPLATE = 'User:URL/chatban'
  BAN_PAGE = 'Project:Chat/Bans'
  REPLACE_TEMP = <<-repl
  ==Temporary bans==
  {| class="wikitable sortable"
    !Username
    !Ban date
    !Ban expires
    !Reason
    !Chatmod issuing ban
    !Notes
    |-
  repl

  def execute(data)
    seconds = data['attrs']['time'].to_i
    return if seconds == 0
    if seconds == 31536000000
      text = '==Permabans==' + @client.api.get(BAN_PAGE).split('==Permabans==')[1]
      @client.api.edit(BAN_PAGE, text.gsub(/\|\}/, <<-repl
      |-
      |[[User:#{data['attrs']['kickedUserName']}|]]
      |#{Time.now.utc.strftime('%B %d, %Y')}
      |To be filled in by [[User:#{data['attrs']['moderatorName']}|]]
      |[[User:#{data['attrs']['moderatorName']}|]]
      |-
      repl
      ), :bot => 1, :summary => "Adding ban for [[User:#{data['attrs']['kickedUserName']}|]]")
    else
      expiry = Time.at(Time.now.to_i + seconds).utc.strftime '%B %d, %Y'
      replace = <<-repl
      ==Temporary bans==
      {| class="wikitable sortable"
      !Username
      !Ban date
      !Ban expires
      !Reason
      !Chatmod issuing ban
      !Notes
      |-
      |[[User:#{data['attrs']['kickedUserName']}|]]
      |#{Time.now.utc.strftime('%B %d, %Y')}
      |#{expiry}
      |To be filled in by [[User:#{data['attrs']['moderatorName']}|]]
      |[[User:#{data['attrs']['moderatorName']}|]]
      |Automatically added by [[User:#{@client.config['user']}|]]
      |-
      repl
      page_text = @client.api.get(BAN_PAGE)
      puts page_text.include? REPLACE_TEMP
      page_text.gsub!(REPLACE_TEMP, replace)
      @client.api.edit(BAN_PAGE, page_text, :summary => "Adding ban for [[User:#{data['attrs']['kickedUserName']}|]]", :bot => 1)
      @client.api.edit('User_talk:' + data['attrs']['kickedUserName'], "{{subst:#{BAN_TEMPLATE}|#{data['attrs']['moderatorName']}|#{expiry}|#{data['attrs']['kickedUserName'].gsub(/ /, '_')}|#{Time.now.utc.strftime("%H:%M, %B %d, %Y (UTC)")}}}", :section => 'new')
    end
  end
end