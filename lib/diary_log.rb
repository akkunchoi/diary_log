# -*- coding: utf-8 -*-

require 'diary_log/record'
require 'diary_log/parser'
require 'diary_log/event'
require 'diary_log/pattern'
require 'diary_log/gcal'
require 'diary_log/controller'

require 'date'
require 'yaml'
require 'pp'

class Hash
  def symbolize_keys_recursive()
    self.inject({}){|result, (key, value)|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then value.symbolize_keys_recursive
                  else value
                  end
      result[new_key] = new_value
      result
    }
  end
end

module DiaryLog
  class Main
    def initialize
      config = YAML.load_file("config.yml").symbolize_keys_recursive
      config[:root] = File.dirname(File.dirname(__FILE__))

      # Override with argv
      require 'optparse'
      require 'active_support'
      opt = OptionParser.new

      opt.on('--gcal-insert') {|v| config[:gcal][:insert] = true }
      opt.on('--gcal-insert-dry-run') {|v| config[:gcal][:insert_dry_run] = true}
      opt.on('--day-ago NUM') {|v| config[:period][:day_ago] = v }
      opt.on('--show-rests') {|v| config[:show_rests] = true}
      opt.on('--show-records') {|v| config[:show_records] = true}
      opt.on('--show-events') {|v| config[:show_events] = true}
      opt.on('--analyze') {|v| config[:analyze] = true}
      opt.on('--last-week [WEEK]') do |v| 
        v = 1 if v.nil? || v == ""
        v = Integer(v)

        base = Date.today + 1
        v.times do
          base = base.prev_week
        end
        s = base - 1 # sunday start
        e = base + 6  # this sunday
        config[:period][:day_ago] = nil
        config[:period][:day_since] = s.strftime("%Y-%m-%d")
        config[:period][:day_until] = e.strftime("%Y-%m-%d")
      end
      opt.on('--since SINCE') do |v| 
        # TODO validation
        config[:period][:day_ago] = nil
        config[:period][:day_since] = v
      end
      opt.on('--until UNTIL') do |v| 
        # TODO validation
        config[:period][:day_ago] = nil
        config[:period][:day_until] = v
      end

      opt.parse!(ARGV)

      ctrl = DiaryLog::Controller.new(config)
      ctrl.run
    end
  end
end


