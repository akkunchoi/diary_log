require 'rspec'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
end

require 'diary_log'
