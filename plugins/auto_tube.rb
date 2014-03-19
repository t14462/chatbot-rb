require 'httparty'

class Chatbot::AutoTube
  include Chatbot::Plugin

  match /https?:\/\/(?:www\.)?youtube\.com[^ ]+v=([^&# ]*)|https?:\/\/(?:www\.)?youtu\.be\/([^&#\? ]*)/im, :use_prefix => false
  match /^yton$/, :method => :enable
  match /^ytoff$/, :method => :disable

  def initialize(bot)
    super(bot)
    @on = true
  end

  def execute(captures, user)
    return if user.ignored? or user.name == @client.config['user']
    video_id = captures[1].nil? ? captures[2] : captures[1]
    @client.send_msg fetch_video_info(video_id)
  end

  def enable(captures, user)
    if !@on and user.is? :mod
      @on = true
      @client.send_msg "#{user.name}: YouTube info enabled!"
    end
  end

  def disable(captures, user)
    if @on and user.is? :mod
      @client.send_msg "#{user.name}: YouTube info disabled :("
      @on = false
    end
  end

  def fetch_video_info(id)
    data = JSON.parse(HTTParty.get("https://gdata.youtube.com/feeds/api/videos/#{id}?v=2&alt=jsonc").body)['data']
    return if data['title'].size > 100
    rating = data.key?('rating') ? data['rating'].round(2) : 0
    duration = get_hms(data['duration'])
    published = data['uploaded'].split(/T/)[0]
    views = data.key?('views') ? data['views'].reverse.scan(/\d{1,3}/).reverse.collect{|e|e.reverse}.join(',') : 0
    "[YOUTUBE] Title: #{data['title']} - Duration: #{duration} - Uploaded: #{published} - Rating: #{rating} - Views: #{views} - http://youtu.be/#{id}"
  end

  def get_hms(seconds)
    hours = seconds / 3600
    seconds %= 3600
    minutes = seconds / 60
    seconds %= 60
    "#{hours}:#{minutes}:#{seconds}"
    "#{minutes}:#{seconds}" if hours == 0
  end

end