# -*- coding: utf-8 -*-

module DiaryLog
  class Event
    attr_reader :title, :start_record, :end_record
    def initialize(title, start_record, end_record)
      @title = title
      @start_record = start_record
      @end_record = end_record
    end
    
    def start_time
      @start_record.datetime
    end
    
    def end_time
      @end_record.datetime
    end
    
    def duration_by_hour
      a = (end_time - start_time) / 3600
      (((a*100).round)/100.0)
    end
    
  end
end