# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name    = 'statefully'
  spec.version = '0.1.4'

  spec.author      = 'Marcin Wyszynski'
  spec.summary     = 'Immutable state with helpers to build awesome things'
  spec.description = spec.summary
  spec.homepage    = 'https://github.com/marcinwyszynski/statefully'
  spec.license     = 'MIT'

  spec.files      = Dir['lib/**/*.rb'] + Dir['spec/**/*.rb']
  spec.test_files = spec.files.grep(/^spec/)

  spec.add_development_dependency 'bundler', '~> 1.14', '>= 1.14.6'
  spec.add_development_dependency 'closing_comments', '~> 0.1', '>= 0.1.1'
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
  spec.add_development_dependency 'yardstick'

  spec.metadata['yard.run'] = 'yard'
end # Gem::Specification
