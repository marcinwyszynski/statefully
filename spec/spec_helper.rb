require 'bundler/setup'
Bundler.setup

require 'pry'

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'statefully'
