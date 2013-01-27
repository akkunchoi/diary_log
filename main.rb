# -*- coding: utf-8 -*-
#
# usage:
#   ruby main.rb
# 
$:.push File.expand_path("../lib", __FILE__)


require 'diary_log'
require 'yaml'

config = YAML.load_file("config.yml")

path = config["path"]

day = Date.today
n = config["day"]
day = day - n + 1

records = []
n.times do 
  filepath = path.sub('%date%', day.to_s)

  if File.exists?(filepath)

    source = IO.read(filepath)
    source = source.gsub(" ", " ") # c2a0 to 20
    records = records + DiaryLog::Parser.new(source).parse.records
    
  end
  day = day + 1
end

#records.each do |r|
#  p r.pretty_str
#end

rest = records.clone

config["patterns"].each do |(title, options)|
  e = {:title => title}
  e[:s] = Regexp.new(options["s"]) if !options["s"].nil?
  e[:e] = Regexp.new(options["e"]) if !options["e"].nil?
  events = DiaryLog::EventDetector.new([e]).detect(records)
  sum = 0
  
  next if events.size == 0
  
  puts ""
  puts "## #{title}"
  puts ""
  
  events.each do |event|
    puts event.start_datetime.strftime("%Y-%m-%d %H:%M") + " " + event.end_datetime.strftime("%Y-%m-%d %H:%M") + " " + event.end_record.desc
    sum = sum + event.duration_by_hour
    rest.delete(event.end_record)
    if !e[:s].nil?
      rest.delete(event.start_record)
    end
  end
  puts "Total: " + (((sum*100).round)/100.0).to_s + " hours"
end

puts ""
puts "## Rest of records"
puts ""

rest.each do |r|
  p r.datetime.strftime("%Y-%m-%d %H:%M") + " " + r.desc
end