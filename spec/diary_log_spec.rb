# -*- coding: utf-8 -*-

require 'spec_helper'

describe DiaryLog do
  
  it "can create period" do
    r = []
    r << DiaryLog::Record.new(Date.new(2012,1,2), 1, 0, "event start")
    r << DiaryLog::Record.new(Date.new(2012,1,2), 8, 30, "event end")
    
    events = DiaryLog::Pattern.new({:s => "event start", :e => "event end", :name => "Event"}).detect(r)
    
    expect(events.size).to eq(1)
    
    event = events.shift
    expect(event.title).to eq("Event")
    expect(event.start_time.strftime("%Y-%m-%d %H:%M")).to eq("2012-01-02 01:00")
    expect(event.end_time.strftime("%Y-%m-%d %H:%M")).to eq("2012-01-02 08:30")
    expect(event.duration_by_hour).to eq(7.5)
    
  end
  
  
  it "should parse" do
    
    data21 =<<EOD
log 2013-01-21

* 今日は 元気 だ
1:00 寝た
18 晩御飯
12 昼ごはん
8:00 起きた

EOD
    
    data22 =<<EOD
log 2013-01-22

* 今日は 元気 だ
1:00 寝た
18 晩御飯
12 昼ごはん
8:00 起きた
EOD
    
    data23 =<<EOD
log 2013-01-23

10 起きた
8 寝た
4 起きた
2:00 起きた
EOD
    
    parser = DiaryLog::Parser.new
    
    records = []
    records = records + parser.parse(data21)
    records = records + parser.parse(data22)
    records = records + parser.parse(data23)
    
    events = DiaryLog::Pattern.new({:s => /寝た/, :e => /起きた/, :name => "睡眠時間"}).detect(records)
    
    event = events.shift
    expect(event.start_time.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-22 01:00")
    
    event = events.shift
    expect(event.start_time.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-23 01:00")
    
    event = events.shift
    expect(event.start_time.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-23 08:00")
  end
end

