require 'httparty'
require 'iso8601'
require_relative '../plugin'

class Chatbot::AutoTube
  include Chatbot::Plugin

  match /(.*)/im, :use_prefix => false
  match /^yton$/, :method => :enable
  match /^ytoff$/, :method => :disable

  YOUTUBE_API_KEY = ENV['YOUTUBE_API_KEY']
  # Thanks to Mark Seymour for the following regex!
  YOUTUBE_VIDEO_REGEXP = /https?:\/\/(?:[a-zA-Z]{2,3}\.)?(?:youtube\.com\/watch)(?:\?(?:[\w=-]+&(?:amp;)?)*v=([\w-]+)(?:&(?:amp;)?[\w=-]+)*)?(?:#[!]?(?:(?:(?:[\w=-]+&(?:amp;)?)*(?:v=([\w-]+))(?:&(?:amp;)?[\w=-]+)*)|(?:[\w=&-]+)))?[^\w-]?|https?:\/\/(?:[a-zA-Z]{2,3}\.)?(?:youtu\.be\/)([\w-]+)/i
  YOUTUBE_API_VIDEO_URL = "https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=%s&key=%s"

  # @param [Chatbot::Client] bot
  def initialize(bot)
    super(bot)
    @on = true
  end

  # @param [User] user
  # @param [String] vid1
  # @param [String] vid2
  def execute(user, message)
    return if user.name == @client.config['user'] or !@on
    # Also thanks to Mark Seymour for this code!
    return unless message.match(YOUTUBE_VIDEO_REGEXP)
    video_ids = message.scan(YOUTUBE_VIDEO_REGEXP).flatten.reject(&:'nil?').uniq
    response = HTTParty.get(YOUTUBE_API_VIDEO_URL % [video_ids.join(','), YOUTUBE_API_KEY], headers: {'User-Agent' => "HTTParty/#{HTTParty::VERSION} #{RUBY_ENGINE}/#{RUBY_VERSION}"})
    videos = response['items']
    videos.each {|video|
      @client.send_msg "YouTube » %<title>s (%<length>s) · by %<uploader>s on %<uploaded>s · ☝%<likes>s - ☟%<dislikes>s · %<views>s views" % {
          title: video['snippet']['title'],
          uploader: video['snippet']['channelTitle'],
          uploaded: Time.parse(video['snippet']['publishedAt']).strftime('%F'),
          length: seconds_to_time(ISO8601::Duration.new(video['contentDetails']['duration']).to_seconds),
          likes: commify_numbers(video['statistics']['likeCount'].to_i),
          dislikes: commify_numbers(video['statistics']['dislikeCount'].to_i),
          views: commify_numbers(video['statistics']['viewCount'].to_i)
      }
    }
  end

  def enable(user)
    if !@on and user.is? :mod
      @on = true
      @client.send_msg "#{user.name}: YouTube info enabled!"
    end
  end

  def disable(user)
    if @on and user.is? :mod
      @client.send_msg "#{user.name}: YouTube info disabled :("
      @on = false
    end
  end

  private

  def seconds_to_time(seconds, div=2)
    parts = [60,60][-div+1..-1] # d h (m)
    ['%02d'] * div * ':' %
        # the .reverse lets us put the larger units first for readability
        parts.reverse.inject([seconds]) {|result, unitsize|
          result[0,0] = result.shift.divmod(unitsize)
          result
        }
  end

  def commify_numbers(n)
    sign, real, decimal = n.to_s.match(/(\+|-)*(\d+)(.\d+)*/).to_a[1..-1]
    [sign, real.reverse.scan(/\d{1,3}/).join(',').reverse, decimal].join
  end

end
