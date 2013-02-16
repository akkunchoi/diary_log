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
      prev = nil
      records.each do |r|
        next if r.all_day
        @patterns.each_with_index do |pattern, i|
          if !pattern[:s].nil? && !pattern[:e].nil? # s, e両方
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
          elsif !pattern[:e].nil? # eのみ
            if pattern[:e].match(r.desc)
              events << Event.new(pattern[:title], prev, r)
              break
            end
          end
        end
        prev = r
      end
      events
    end
  end
  
end
