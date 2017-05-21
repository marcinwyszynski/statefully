# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name    = 'statefully'
  spec.version = '0.1.3'

  spec.author      = 'Marcin Wyszynski'
  spec.summary     = 'Immutable state with helpers to build awesome things'
  spec.description = spec.summary
  spec.homepage    = 'https://github.com/marcinwyszynski/statefully'
  spec.license     = 'MIT'

  spec.files      = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']
  spec.test_files = spec.files.grep(/^spec/)

  spec.add_development_dependency 'bundler', '~> 1.14', '>= 1.14.6'
  spec.add_development_dependency 'rake', '~> 12.0'
end # Gem::Specification
