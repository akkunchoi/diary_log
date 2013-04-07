# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DiaryLog::Record do
  context "timed" do
    subject{
      @before = DiaryLog::Record.new(Date.new(2011, 12, 31), 23, 0, "b")
      @after = DiaryLog::Record.new(Date.new(2012, 1, 1), 5, 0, "a")
      DiaryLog::Record.new(Date.new(2012, 1, 1), 3, 0, "食事した")
    }
    its(:datetime){ should eq Time.local(2012,1,1,3,0) }
    its(:time_str){ should eq "03:00" }
    its(:pretty_str){ should eq "2012-01-01 03:00 食事した" }

    it 'compares as before' do
      expect(subject).to be > @before
    end
    it 'compares as after' do
      expect(subject).to be < @after
    end
  end
  
  context "all day" do
    subject{
      DiaryLog::Record.new(Date.new(2012, 1, 1), '*', nil, 'あああ')
    }
    its(:datetime){ should eq Time.local(2012,1,1,0,0) }
    its(:time_str){ should eq "*" }
    its(:pretty_str){ should eq "2012-01-01 *     あああ" }
    its(:all_day){ should be_true }
  end
end

