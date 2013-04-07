# -*- coding: utf-8 -*-
module DiaryLog
  class Controller
    def initialize(config)
      @config = config
    end
    
    def build_records(options)
      day_start = options[:day_start]
      day_end = options[:day_end]
      path = options[:path]
      
      parser = DiaryLog::Parser.new
      
      records = []
      day = day_start
      while day <= day_end do
        filepath = path.sub('%date%', day.to_s)

        if File.exists?(filepath)

          source = IO.read(filepath)
          source = source.gsub(" ", " ") # c2a0 to 20
          records = records + parser.parse(source)

        end
        day = day + 1
      end
      
      return records
    end
    
    def patterns
      @config[:patterns].map do |params|
        params = params.symbolize_keys_recursive
        DiaryLog::Pattern.new(params)
      end
    end
    
    def run
      records = build_records(input)

      if @config[:show_records] 
        show_records(records)
      end

      # イベントとして使われなかったレコードを知りたい
      rest = records.clone

      patterns.each do |pattern|
        events = pattern.detect(records)

        events.each do |event|
          rest.delete(event.end_record)
          if pattern.params[:s]
            rest.delete(event.start_record)
          end
        end
        
        # next if events.size == 0

        show_events(pattern, events)
        
        if @config[:gcal][:insert]
          insert_into_gcal(pattern, events)
        end
        
      end

      if @config[:show_rests] 
        show_rest_records(rest)
      end
      
    end
    
    def show_events(pattern, events)
      puts ""
      puts "## #{pattern.name}"
      puts ""

      sum = 0
      events.each do |event|
        puts [
          event.start_time.strftime("%Y-%m-%d %H:%M"), 
          event.end_time.nil? ? '' : event.end_time.strftime("%Y-%m-%d %H:%M"),
          "(" + event.duration_by_hour.to_s + " h)",
          event.end_time.nil? ? event.start_record.desc : event.end_record.desc
          ].join(' ')
        sum = sum + event.duration_by_hour
      end
      puts "Total: " + (((sum*100).round)/100.0).to_s + " hours"
    end
    
    def show_records(records)
      puts ""
      puts "## records"
      puts ""

      records.each do |r|
        p r.datetime.strftime("%Y-%m-%d %H:%M") + " " + r.desc
      end      
    end

    def show_rest_records(records)
      puts ""
      puts "## The rest of records"
      puts ""

      records.each do |r|
        p r.datetime.strftime("%Y-%m-%d %H:%M") + " " + r.desc
      end      
    end
    
    def insert_into_gcal(pattern, events)
      events.each do |event|
        if gcal.create_event(pattern, event)
          puts "The event '" + event.desc + "' was created on gcal."
        end
      end
    end
    
    def gcal
      @gcal = @gcal || DiaryLog::Gcal.new(
        @config[:gcal].merge({:basepath => @config[:root]})
      )
    end
    
    
    protected
    def input
      config = @config
      
      if !config[:period][:day_ago].nil?
        day_end = Date.today
        day_start = day_end - config[:period][:day_ago] + 1
      elsif !config[:period][:day_since].nil? && !config[:period][:day_until].nil?
        day_start = Date.strptime(config[:period][:day_since], "%Y-%m-%d") 
        day_end = Date.strptime(config[:period][:day_until], "%Y-%m-%d") 
      end

      if day_start.nil? || day_end.nil?
        puts "Please specify day_ago or (day_since and day_until)"
        exit 1
      end
      puts day_start.to_s + " to " + day_end.to_s
      
      return {:day_start => day_start, :day_end => day_end, :path => config[:path]}
    end
    
    
    
  end
end
