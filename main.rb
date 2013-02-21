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
 
ctrl = DiaryLog::Controller.new(config)
ctrl.run


