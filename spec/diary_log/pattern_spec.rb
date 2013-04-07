# -*- encoding: utf-8 -*-

require 'spec_helper'

describe DiaryLog::Pattern do
  before do
    @records = [
      DiaryLog::Record.new(Date.new(2013, 1, 2), '*', 0, "今日は、ほげほげだ"),
      DiaryLog::Record.new(Date.new(2013, 1, 2), 3, 0, "開始"),
      DiaryLog::Record.new(Date.new(2012, 1, 2), 4, 30, "aaa"),
      DiaryLog::Record.new(Date.new(2012, 1, 2), 6, 50, "終了")
    ]
  end
  
  context 'ranged detector' do
    subject{
      DiaryLog::Pattern.new({:s => '開始', :e => '終了', :name => 'テストイベント'})
    }
    its(:name){ should eq 'テストイベント'}

    describe 'detect' do
      before do
        @events = subject.detect(@records)
      end
      it "detects one event" do
        expect(@events.size).to eq 1
        expect(@events.first.title).to eq 'テストイベント'
        expect(@events.first.start_record.time_str).to eq '03:00'
      end
    end

  end
  
  context 'end-base detector' do
    subject{
      DiaryLog::Pattern.new({:e => '終了', :name => 'テストイベント'})
    }
    its(:name){ should eq 'テストイベント'}

    describe 'detect' do
      before do
        @events = subject.detect(@records)
      end
      it "detects one event" do
        expect(@events.size).to eq 1
        expect(@events.first.title).to eq 'テストイベント'
        expect(@events.first.start_record.time_str).to eq '04:30'
      end
    end

  end
  
  context 'all-day detector' do
    subject{
      DiaryLog::Pattern.new({:a => '今日は、', :name => '全日イベント'})
    }
    its(:name){ should eq '全日イベント'}

    describe 'detect' do
      before do
        @events = subject.detect(@records)
      end
      it "detects one event" do
        expect(@events.size).to eq 1
        expect(@events.first.title).to eq '全日イベント'
        expect(@events.first.start_record.time_str).to eq '*'
      end
    end

  end
end

