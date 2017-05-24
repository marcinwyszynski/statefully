require 'bundler/setup'
Bundler.setup

require 'pry'

if ENV['CI'] == 'true'
  require 'codecov'
  require 'simplecov'

  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'statefully'
