# -*- coding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)

require 'diary_log'

path = "/Users/akiyoshi/Dropbox/PlainText/log %date%.txt"

day = Date.today
n = 30
day = day - n + 1

records = []
n.times do 
  filepath = path.sub('%date%', day.to_s)

  if File.exists?(filepath)

    source = IO.read(filepath)
    records = records + DiaryLog::Parser.new(source).parse.records
    
  end
  day = day + 1
end

events = DiaryLog::EventDetector.new([{:s => /寝た/, :e => /起きた/, :title => "睡眠時間"}]).detect(records)
sum = 0
events.each do |event|
  p event.start_datetime.strftime("%Y-%m-%d %H:%M") + " " + event.end_datetime.strftime("%Y-%m-%d %H:%M")
  sum = sum + event.duration_by_hour
end

p sum / n
