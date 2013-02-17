# -*- coding: utf-8 -*-
#
# usage:
#   ruby main.rb
# 
$:.push File.expand_path("../lib", __FILE__)


require 'diary_log'
require 'yaml'
require 'date'

config = YAML.load_file("config.yml")

ctrl = DiaryLog::Controller.new(config)
ctrl.run