# -*- coding: utf-8 -*-

module DiaryLog
  class Event
    attr_reader :title, :start_record, :end_record
    def initialize(title, start_record, end_record = nil)
      @title = title
      @start_record = start_record
      @end_record = end_record
    end
    
    def start_time
      @start_record.datetime
    end
    
    def end_time
      if @end_record.nil?
        return nil
      end
      @end_record.datetime
    end
    
    def duration_by_hour
      return 0 if end_time.nil?
      
      a = (end_time - start_time) / 3600
      (((a*100).round)/100.0)
    end
    
    def desc
      if end_time.nil?
        start_record.desc
      else
        end_record.desc
      end
    end
  end
end