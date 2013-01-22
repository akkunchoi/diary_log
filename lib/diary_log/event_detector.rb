# -*- coding: utf-8 -*-

module DiaryLog
  class EventDetector
    
    def initialize(patterns)
      @patterns = patterns
    end
    
    def detect(records)
      events = []
      now_event = nil
      now_start_record = nil
      records.each do |r|
        @patterns.each_with_index do |pattern, i|
          if !now_event.nil? && now_event[:e].match(r.desc)
            events << Event.new(now_event[:title], now_start_record, r)
            now_event = nil
            now_start_record = nil
            break
          end
          if pattern[:s].match(r.desc)
            now_event = pattern
            now_start_record = r
            break
          end
        end
      end
      events
    end
  end
  
end
