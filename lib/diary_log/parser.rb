# -*- coding: utf-8 -*-

require "date"
require "diary_log/record"

module DiaryLog
  class Parser
    
    def initialize(options = {})
      if options[:logger]
        @logger = options[:logger]
      end
    end

    def parse(source)
      records = []
      a = source.split(/\n/).map{|line| line.strip }.reject{|line| line.size == 0}
      
      first = a.shift
      
      m = first.match(/(?<year>\d+)\-(?<month>\d+)\-(?<day>\d+)/)
      
      if m.nil? || m.size != 4
        raise "Syntax Error"
      end
      
      date = Date.new(m[:year].to_i, m[:month].to_i, m[:day].to_i)

      prev = nil
      
      a.reverse.each do |line|
        
        unless line.match(/^\*|^\d/)
          # not log record or other text
          next
        end

        time, desc = line.split(' ', 2)
        hour, minute = time.split(':', 2)
        
        if desc.nil?
          # no desc
          next
        end
        
        r = Record.new(date, hour, minute, desc)
        
        if !prev.nil? && prev > r
          r.after_midnight!

          # ちょっと開きすぎてる。間違いかも？
          if (r.datetime - prev.datetime) > 20 * 3600
            @logger.warn "20時間以上記録がありません: " + r.pretty_str
          end
        end
        
        records << r
        prev = r
      end
      
      records
    end

  end
end
