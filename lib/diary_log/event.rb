# -*- coding: utf-8 -*-

module DiaryLog
  class Event
    attr_reader :title, :start_record, :end_record
    def initialize(title, start_record, end_record)
      @title = title
      @start_record = start_record
      @end_record = end_record
    end
    
    def start_datetime
      @start_record.datetime
    end
    
    def end_datetime
      @end_record.datetime
    end
    
    def duration_by_hour
      (end_datetime.to_time - start_datetime.to_time) / 3600
    end
  end
end