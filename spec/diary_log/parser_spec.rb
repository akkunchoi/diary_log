# -*- encoding: utf-8 -*-

require 'spec_helper'

describe DiaryLog::Event do

  context 'invalid date subject' do
    it 'parse' do
      source = <<EOS
INVALID DATE
EOS
      expect{ DiaryLog::Parser.new.parse(source) }.to raise_error
    end
  end

  context 'invalid order warning' do
    it 'warning' do
      source = <<EOS
log 2013-01-22
1 event1
2 event2
EOS
      logger = mock('logger')
      logger.should_receive(:warn).with(/20時間以上記録がありません/)
      DiaryLog::Parser.new(logger: logger).parse(source)
    end
  end

  context 'ignore case' do
    subject{
      source = <<EOS
log 2013-01-22

7
6 
- 関係ないテキスト
EOS
      DiaryLog::Parser.new.parse(source)
    }
    its(:size) { should be 0}
  end

  context 'default' do
    subject{
      source = <<EOS
log 2013-01-22

* 今日は 元気 だ
1:00 寝た
18 晩御飯
12 昼ごはん
8:00 起きた
EOS
      DiaryLog::Parser.new.parse(source)
    }
    its(:size) { should be 5}
    
    it "returns all_day" do
      expect(subject[0].all_day).to be false
      expect(subject[1].all_day).to be false
      expect(subject[4].all_day).to be true
    end
    
    it "returns desc" do
      expect(subject[0].desc).to eq '起きた'
    end
    
    it "expects records" do
      result = [
        '2013-01-22 08:00 起きた',
        '2013-01-22 12:*  昼ごはん',
        '2013-01-22 18:*  晩御飯',
        '2013-01-22 25:00 寝た',
        '2013-01-22 *     今日は 元気 だ',
      ]
      
      expect(subject.map {|r| r.pretty_str }).to eq(result)
      
    end
  end
  
end