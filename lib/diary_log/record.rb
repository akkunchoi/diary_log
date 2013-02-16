module DiaryLog
  class Record
    ALL_DAY = '*'
    attr_reader :date, :hour, :minute, :all_day, :desc

    def initialize(date, hour, minute, desc)
      @date = date
      if hour == ALL_DAY
        @all_day = true
      else
        @all_day = false
        @hour = hour.to_i
        @minute = minute.to_i unless minute.nil?
      end
      @desc = desc
    end

    def datetime
      date = @date
      hour = @hour
      if hour.nil?
        return DateTime.new(date.year, date.month, date.day)
      end
      if hour >= 24
        date = date + 1
        hour = hour - 24
      end
      if @minute.nil?
        return DateTime.new(date.year, date.month, date.day, hour)
      else
        return DateTime.new(date.year, date.month, date.day, hour, @minute)
      end
    end
    
    def time_str
      if @all_day
        return ALL_DAY
      end
      
      if @minute.nil?
        return @hour.to_s + ':' + ALL_DAY
      end
      
      sprintf("%02d:%02d", @hour, @minute)
    end

    def space(str, n)
      if str.size < n
        return str + " " * (n - str.size)
      end
      str
    end
    
    def pretty_str
      date.strftime("%Y-%m-%d") + " " + space(time_str, 5) + " " + desc
    end

    def after_midnight!
      @hour = @hour + 24
    end
    
    def <=> (other)
      a = @date <=> other.date
      return a unless a == 0
      
      # 全日イベントは比較しないようにしたいが
      if @all_day || other.all_day
        return 0
      end
      
      a = @hour <=> other.hour
      return a unless a == 0
      
      a = @minute <=> other.minute
      return a
      
    end
    def > (other)
      (self <=> other) == 1
    end
    def < (other)
      (self <=> other) == -1
    end
  end
end

