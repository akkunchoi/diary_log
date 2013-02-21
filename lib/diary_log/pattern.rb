# -*- coding: utf-8 -*-
module DiaryLog
  
  class Pattern
    attr_reader :params
    
    def initialize(params)
      params[:s] = Regexp.new(params[:s]) if !params[:s].nil?
      params[:e] = Regexp.new(params[:e]) if !params[:e].nil?
      @params = params
    end
    def name
      params[:name]
    end
    def match(r)
      if params[:s].match(r.desc)
        return :start
      end
      return nil
    end

    def detect(records)
      detector.detect(records)
    end
    
    def detector
      if !params[:s].nil? && !params[:e].nil?
        EventDetector::Ranged.new(self)
      else
        EventDetector::EndBase.new(self)
      end
    end
    
    class EventDetector
      def initialize(pattern)
        @pattern = pattern
      end

      def detect(records)
        events = []
        detector = @pattern.detector
        records.each do |r|
          next if r.all_day
          e = detector.match(r)
          if e
            events << e
          end
        end
        events
      end

      class Ranged < EventDetector
        def match(r)
          params = @pattern.params
          if @now_record && params[:e].match(r.desc)
            event = Event.new(@pattern.name, @now_record, r)
            @now_record = nil
            return event
          end
          if params[:s].match(r.desc)
            @now_record = r
          end
          return nil
        end
      end

      class EndBase < EventDetector
        def match(r)
          params = @pattern.params
          if params[:e].match(r.desc)
            event = Event.new(@pattern.name, @prev, r)
            @prev = r
            return event
          end
          @prev = r
          return nil
        end
      end
    end
    
  end
end