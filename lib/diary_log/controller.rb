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
      
      records = []
      day = day_start
      while day <= day_end do
        filepath = path.sub('%date%', day.to_s)

        if File.exists?(filepath)

          source = IO.read(filepath)
          source = source.gsub(" ", " ") # c2a0 to 20
          records = records + DiaryLog::Parser.new(source).parse.records

        end
        day = day + 1
      end
      
      return records
    end
    
    def patterns
      @config['patterns'].map do |(id, params)|
        params[:id] = id
        DiaryLog::Pattern.new(params)
      end
    end
    
    def run
      records = build_records(input)

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

        show_events(pattern.params[:id], events)
      end

      show_rest_records(rest)
      
    end
    
    def show_events(title, events)
      puts ""
      puts "## #{title}"
      puts ""

      sum = 0
      events.each do |event|
        puts event.start_datetime.strftime("%Y-%m-%d %H:%M") + " " + event.end_datetime.strftime("%Y-%m-%d %H:%M") + " " + event.end_record.desc
        sum = sum + event.duration_by_hour
      end
      puts "Total: " + (((sum*100).round)/100.0).to_s + " hours"
    end
    
    def show_rest_records(records)
      puts ""
      puts "## The rest of records"
      puts ""

      records.each do |r|
        p r.datetime.strftime("%Y-%m-%d %H:%M") + " " + r.desc
      end      
    end
    
    
    protected
    def input
      config = @config
      
      if !config["period"]["day_ago"].nil?
        day_end = Date.today
        day_start = day_end - config["period"]["day_ago"] + 1
      elsif !config["period"]["day_since"].nil? && !config["period"]["day_until"].nil?
        day_start = Date.strptime(config["period"]["day_since"], "%Y-%m-%d") 
        day_end = Date.strptime(config["period"]["day_until"], "%Y-%m-%d") 
      end

      if day_start.nil? || day_end.nil?
        puts "Please specify day_ago or (day_since and day_until)"
        exit 1
      end
      puts day_start.to_s + " to " + day_end.to_s
      
      return {:day_start => day_start, :day_end => day_end, :path => config['path']}
    end
    
    
    
  end
end