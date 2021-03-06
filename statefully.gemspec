$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'statefully/version'

Gem::Specification.new do |spec|
  spec.name    = 'statefully'
  spec.version = Statefully::VERSION

  spec.author   = 'Marcin Wyszynski'
  spec.email    = 'marcinw [at] gmx [dot] com'
  spec.summary  = 'Immutable state with helpers to build awesome things'
  spec.homepage = 'https://github.com/marcinwyszynski/statefully'
  spec.license  = 'MIT'

  spec.files      = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']
  spec.test_files = spec.files.grep(/^spec/)

  spec.add_development_dependency 'bundler', '~> 1.14', '>= 1.14.6'
  spec.add_development_dependency 'codecov', '~> 0.1', '>= 0.1.10'
  spec.add_development_dependency 'ensure_version_bump', '~> 0.1'
  spec.add_development_dependency 'pry', '~> 0.10', '>= 0.10.4'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'reek', '~> 4.6', '>= 4.6.2'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 0.49'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.15', '>= 1.15.1'
  spec.add_development_dependency 'simplecov', '~> 0.14', '>= 0.14.1'
  spec.add_development_dependency 'yard', '~> 0.9', '>= 0.9.9'
  spec.add_development_dependency 'yardstick', '~> 0.9', '>= 0.9.9'

  spec.metadata['yard.run'] = 'yard'
end
