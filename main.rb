# -*- coding: utf-8 -*-
#
# usage:
#   ruby main.rb
# 
$:.push File.expand_path("../lib", __FILE__)


require 'diary_log'
require 'yaml'
require 'date'

config = YAML.load_file("config.yml")

path = config["path"]

if !config["period"]["day_ago"].nil?
  day_end = Date.today
  day_start = day_end - config["period"]["day_ago"] + 1
elsif !config["period"]["day_since"].nil? && !config["period"]["day_until"].nil?
  day_start = Date.strptime(config["period"]["day_since"], "%Y-%m-%d") 
  day_end = Date.strptime(config["period"]["day_until"], "%Y-%m-%d") 
end

if day_start.nil? || day_end.nil?
  puts "Please specify day_ago or (day_since and day_until)"
  exit 1
end

puts day_start.to_s + " to " + day_end.to_s

records = []
day = day_start
while day <= day_end do
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
puts "## The rest of records"
puts ""

rest.each do |r|
  p r.datetime.strftime("%Y-%m-%d %H:%M") + " " + r.desc
end