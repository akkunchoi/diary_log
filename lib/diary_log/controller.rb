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
      
      day_option = input
      puts "#{day_option[:day_start]} to #{day_option[:day_end]}"
      
      records = build_records(day_option)

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
        
       next if events.size == 0

        unless @config[:analysis]
          show_events(pattern, events)
        end
        
        if @config[:gcal][:insert]
          insert_into_gcal(pattern, events)
        end
        
        if @config[:analysis]
          analyze_events(pattern, events)
        end
        
      end

      if @config[:analysis]
        analyze_events_result
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
    
    def analyze_events(pattern, events)
      @events = @events || {}
      @events[pattern.name] = (@events[pattern.name] || []) + events
    end
    def analyze_events_result
      unit = @config[:analysis][:unit]
      
      puts "------------------------------------"
      @events.each do |name, events|
        next if events.size == 0
        puts ""
        puts "## #{name}"
        puts ""
#        puts "#{events.size} events."
        
        #区切り開始日
        span = input[:day_start]
        case unit
        when "week"; span = span.__send__("beginning_of_#{unit}", :sunday)
        when "month"; span = span.__send__("beginning_of_#{unit}")
        end
        sum = 0
        events.each do |event|
          if event.start_time >= span
            prev = span.__send__("prev_#{unit}")
            day = span - prev
            puts sprintf("%s to %s % 6.1fh (% 5.1fh )  %s", prev, span - 1, sum, sum/day, "*" * (sum/day).to_i) if sum > 0
            while event.start_time >= span
              span = span.__send__("next_#{unit}")
            end
            sum = 0
          end
          sum = sum + event.duration_by_hour
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
      
      return {:day_start => day_start, :day_end => day_end, :path => config[:path]}
    end
    
    
    
  end
end
