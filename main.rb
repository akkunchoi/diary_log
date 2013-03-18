# -*- coding: utf-8 -*-
#
# usage:
#   ruby main.rb
# 
$:.push File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'diary_log'
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

config = YAML.load_file("config.yml").symbolize_keys_recursive
config[:root] = File.dirname(__FILE__)

# Override with argv
require 'optparse'
require 'active_support'
opt = OptionParser.new

opt.on('--gcal-insert') {|v| config[:gcal][:insert] = true }
opt.on('--day-ago NUM') {|v| config[:period][:day_ago] = v }
opt.on('--show-rests') {|v| config[:show_rests] = true}
opt.on('--last-week') do |v| 
  base = Date.today + 1
  s = base.prev_week - 1 # sunday start
  e = base.prev_week + 7 # this sunday
  config[:period][:day_ago] = nil
  config[:period][:day_since] = s.strftime("%Y-%m-%d")
  config[:period][:day_until] = e.strftime("%Y-%m-%d")
end

opt.parse!(ARGV)

ctrl = DiaryLog::Controller.new(config)
ctrl.run


