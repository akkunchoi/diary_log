# -*- coding: utf-8 -*-
module DiaryLog
  
  class Pattern
    attr_reader :params
    
    def initialize(params)
      params[:s] = Regexp.new(params[:s]) if !params[:s].nil?
      params[:e] = Regexp.new(params[:e]) if !params[:e].nil?
      params[:a] = Regexp.new(params[:a]) if !params[:a].nil?
      params[:m] = Regexp.new(params[:m]) if !params[:m].nil?
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
      if !params[:m].nil?
        EventDetector::Match.new(self)
      elsif !params[:s].nil? && !params[:e].nil?
        EventDetector::Ranged.new(self)
      elsif !params[:a].nil?
        EventDetector::AllDay.new(self)
      elsif !params[:e].nil?
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
          e = detector.match(r)
          if e
            events << e
          end
        end
        events
      end

      class Match < EventDetector
        def match(r)
          return nil if r.all_day
          m = @pattern.params[:m].match(r.desc)
          if m
            event = Event.new(@pattern.name, r)
            return event
          end
        end
      end

      class Ranged < EventDetector
        def match(r)
          return nil if r.all_day
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
          return nil if r.all_day
          if params[:e].match(r.desc)
            event = Event.new(@pattern.name, @prev, r)
            @prev = r
            return event
          end
          @prev = r
          return nil
        end
      end
      
      class AllDay < EventDetector
        def match(r)
          params = @pattern.params
          if r.all_day && params[:a].match(r.desc)
            return Event.new(@pattern.name, r)
          end
          return nil
        end
      end
    end
    
  end
end