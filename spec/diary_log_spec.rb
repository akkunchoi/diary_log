# -*- coding: utf-8 -*-

require 'rspec'
require 'diary_log'

describe DiaryLog do
  it "can parse" do
    
    data22 =<<EOD
log 2013-01-22

* 今日は 元気 だ
1:00 寝た
18 晩御飯
12 昼ごはん
8:00 起きた

EOD
    
    result = [
      '2013-01-22 08:00 起きた',
      '2013-01-22 12:*  昼ごはん',
      '2013-01-22 18:*  晩御飯',
      '2013-01-22 25:00 寝た',
      '2013-01-22 *     今日は 元気 だ',
    ]
    
    expect(DiaryLog::Parser.new(data22).parse.to_s).to eq(result.join("\n"))
    
  end
  
  it "can create period" do
    r = []
    r << DiaryLog::Record.new(Date.new(2012,1,2), 1, 0, "event start")
    r << DiaryLog::Record.new(Date.new(2012,1,2), 8, 30, "event end")
    
    events = DiaryLog::EventDetector.new([{:s => /event start/, :e => /event end/, :title => "Event"}]).detect(r)
    
    expect(events.size).to eq(1)
    
    event = events.shift
    expect(event.title).to eq("Event")
    expect(event.start_datetime.strftime("%Y-%m-%d %H:%M")).to eq("2012-01-02 01:00")
    expect(event.end_datetime.strftime("%Y-%m-%d %H:%M")).to eq("2012-01-02 08:30")
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
    
    records = []
    records = records + DiaryLog::Parser.new(data21).parse.records
    records = records + DiaryLog::Parser.new(data22).parse.records
    records = records + DiaryLog::Parser.new(data23).parse.records
    
    events = DiaryLog::EventDetector.new([{:s => /寝た/, :e => /起きた/, :title => "睡眠時間"}]).detect(records)
    
    event = events.shift
    expect(event.start_datetime.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-22 01:00")
    
    event = events.shift
    expect(event.start_datetime.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-23 01:00")
    
    event = events.shift
    expect(event.start_datetime.strftime("%Y-%m-%d %H:%M")).to eq("2013-01-23 08:00")
  end
end

