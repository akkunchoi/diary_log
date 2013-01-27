# -*- coding: utf-8 -*-

require "date"
require "diary_log/record"

module DiaryLog
  class Parser
    
    attr_reader :records
    
    def initialize(source)
      @source = source
      @date = nil
      @records = []
    end
    
    def parse
      a = @source.split(/\n/).map{|line| line.strip }.reject{|line| line.size == 0}
      
      first = a.shift
      
      m = first.match(/(?<year>\d+)\-(?<month>\d+)\-(?<day>\d+)/)
      
      if m.nil? || m.size != 4
        raise "Syntax Error"
      end
      
      @date = Date.new(m[:year].to_i, m[:month].to_i, m[:day].to_i)

      prev = nil
      
      a.reverse.each do |line|
        time, desc = line.split(' ', 2)
        hour, minute = time.split(':', 2)
        
        if desc.nil?
          # no desc
          next
        end
        
        r = Record.new(@date, hour, minute, desc)
        
        if !prev.nil? && prev > r
          r.after_midnight!
        end
        
        @records << r
        prev = r
      end
      
      @records
      
      self
    end
    
    def to_s
      @records.map {|r| r.pretty_str }.to_a.join("\n")
    end
  end
end