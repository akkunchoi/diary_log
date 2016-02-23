# -*- coding: utf-8 -*-
require 'logger'

module DiaryLog
  class Controller
    def initialize(config)
      @config = config
      @logger = Logger.new(STDERR)
    end
    
    def build_records(options)
      day_start = options[:day_start]
      day_end = options[:day_end]
      path = options[:path]
      
      parser = DiaryLog::Parser.new(logger: @logger)
      
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

      unless @config[:output_json]
        puts "#{day_option[:day_start]} to #{day_option[:day_end]}"
      end
      
      records = build_records(day_option)

      if @config[:show_records] 
        show_records(records)
      end

      # イベントとして使われなかったレコードを知りたい
      rest = records.clone

      patterns.each do |pattern|
        
        sunriseOption = {:hour => 7, :min => 0, :sec => 0}
        sunsetOption = {:hour => 19, :min => 0, :sec => 0}

        # 日照時間の睡眠計算する
        # daylight=trueのイベントのみ、v:sunrise/v:sunsetという仮想レコードを追加する
        # 
        # sunrise - sleep   * wake    - sunset
        # sunrise - sleep   * sunset  - wake
        # sunrise * wake    - sleep   * sunset
        # sunrise * wake    - sunset  - sleep
        # sleep   - sunrise * wake    - sunset
        # sleep   - sunrise * sunset  - wake
        # sunset  - sleep   - wake    - sunrise
        # 
        if pattern.params[:daylight]
          # sunrise/sunset仮想レコードを追加
          new_records = []
          prev_record = nil
          records.each do |record|
            sunrise = record.datetime.change(sunriseOption)
            sunset = record.datetime.change(sunsetOption)
            if !prev_record.nil?
              if prev_record.datetime < sunrise && sunrise < record.datetime
                new_records << Record.new(sunrise, sunrise.hour, sunrise.min, "v:sunrise")
              end
              if prev_record.datetime < sunset && sunset < record.datetime
                new_records << Record.new(sunset, sunset.hour, sunset.min, "v:sunset")
              end
            end
            prev_record = record
            new_records << record
          end
          events = pattern.detect(new_records)
          
          events = events.reject do |event|
            sleep_time = event.start_record.datetime
            sunset = sleep_time.change(sunsetOption)
            # 直近のsunset時間を求めたい
            if sunset > sleep_time
              sunset = sunset - 86400
            end
            wake_time = event.end_record.datetime
            sunrise = wake_time.change(sunriseOption)
            
            sunset <= sleep_time && wake_time <= sunrise 
          end
        else
          events = pattern.detect(records)
        end

        events.each do |event|
          rest.delete(event.end_record)
          if pattern.params[:s]
            rest.delete(event.start_record)
          end
          if pattern.params[:m]
            rest.delete(event.start_record)
          end
          if pattern.params[:a]
            rest.delete(event.start_record)
          end
        end
       
        # bug
       #next if events.size == 0

        if @config[:show_events]
          show_events(pattern, events)
        end
        
        if @config[:gcal][:insert]
          insert_into_gcal(pattern, events)
        end
        
        if @config[:analyze] || @config[:output_json]
          analyze_events(pattern, events)
        end
        
      end

      if @config[:analyze]
        analyze_events_result
      end
        
      if @config[:show_rests] 
        show_rest_records(rest)
      end

      if @config[:output_json]
        output_events
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
    
    # weekの場合は :sunday を渡すのを透過的にしたい
    def date_at(method, unit, date)
      case unit
      when "week"; date.__send__("#{method.to_s}_#{unit}", :sunday)
      when "month"; date.__send__("#{method.to_s}_#{unit}")
      end
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
        
        event_sum = 0

        #区切り開始日
        span = input[:day_start]
        span = date_at(:beginning_of, unit, span)
        sum = 0
        d = 0

        # event.eachより区切り時間でeachした方が良いかも。。
        #
        events << :eoe # end of event
        events.each do |event|
          span_time = Time.local(span.year, span.month, span.day, 0, 0, 0)
         
          # eventの最後か
          # イベント開始時間 > 区切り開始時間の場合、それまでの合計を出力
          if event == :eoe || event.start_time >= span_time
            prev = date_at(:prev, unit, span)
            day = span - prev
            puts sprintf("%s to %s % 6.1fh/w (% 5.1fh/d)  %s", prev, span - 1, sum, sum/day, "*" * (sum/day).to_i) if sum > 0
            # puts sprintf("            -- daylight % 6.1fh             %s", d, "*" * d.to_i) if d > 0

            next if event == :eoe
            
            # イベントのある週/月まで区切り開始時間を進める
            # event.start_time < span_time となる直前の値
            n_span = span = date_at(:next, unit, span)
            begin
              span = n_span
              n_span = date_at(:next, unit, span)
              span_time = Time.local(n_span.year, n_span.month, n_span.day, 0, 0, 0)
            end while event.start_time > span_time

            sum = 0
            d = 0
          end

          sum = sum + event.duration_by_hour
          event_sum = event_sum + event.duration_by_hour
          
        end
        puts sprintf("event sum %d h", event_sum)

      end
    end
    
    def gcal
      @gcal = @gcal || DiaryLog::Gcal.new(
        @config[:gcal].merge({:basepath => @config[:root]})
      )
    end
    
    def output_events
      obj = {
        :config => @config,
        :data => @events
      }
      puts "DiaryLog = " + obj.to_json
      # puts "DiaryLog = {data: " + @events.to_json + "};"
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
