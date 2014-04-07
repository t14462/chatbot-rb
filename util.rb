require 'json'
module JSON
  def self.is_json?(foo)
    begin
      return false unless foo.is_a?(String)
      self.parse(foo).all?
    rescue self::ParserError
      false
    end
  end
end

class User
  attr_reader :name
  def initialize(name, mod = false, admin = false, staff = false)
    @name = name
    @mod = mod
    @admin = admin
    @staff = staff
  end

  def is?(right)
    case right
      when :mod
        @mod or @admin or @staff or is? :dev
      when :admin
        @admin or @staff or is? :dev
      when :staff
        @staff or is? :dev
      when :dev
        @name.eql? 'Sactage'
      else
        false
    end
  end

  def log_name
    @name.gsub(' ', '_')
  end

  def ignored?
    if File.exists? 'ignore.yml'
      YAML::load_file('ignore.yml')['users'].include? @name
    else
      File.open('ignore.yml', 'w+') {|f| f.write({'users' => []}.to_yaml)}
      false
    end
  end

  def ignore
    if File.exists? 'ignore.yml'
      ignorefile = YAML::load_file('ignore.yml')
    else
      ignorefile = {'users' => []}
    end
    ignorefile['users'] << @name
    File.open('ignore.yml', 'w+') {|f| f.write(ignorefile.to_yaml)}
  end

  def unignore
    if File.exists? 'ignore.yml'
      ignorefile = YAML::load_file('ignore.yml')
    else
      ignorefile = {'users' => []}
    end
    ignorefile['users'].delete(@name)
    File.open('ignore.yml', 'w+') {|f| f.write(ignorefile.to_yaml)}
  end
end

module Util
  LOG_TS_FORMAT = "[%Y-%m-%d %H:%M:%S]"
  def self.ts
    Time.now.utc.strftime LOG_TS_FORMAT
  end
end