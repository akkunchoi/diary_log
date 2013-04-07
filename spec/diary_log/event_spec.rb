# -*- encoding: utf-8 -*-

require 'spec_helper'

describe DiaryLog::Event do
  
  context '' do
    subject{
      DiaryLog::Event.new(
        'あああ',
        DiaryLog::Record.new(Date.new(2012, 1, 2), 3, 0, "開始"),
        DiaryLog::Record.new(Date.new(2012, 1, 2), 6, 30, "終了")
      )
    }
    its(:duration_by_hour) { should eq 3.5}
    
  end
  
end

