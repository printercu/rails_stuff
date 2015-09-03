# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_stuff/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_stuff'
  spec.version       = RailsStuff::VERSION::STRING
  spec.authors       = ['Max Melentiev']
  spec.email         = ['m.melentiev@corp.mail.ru']

  spec.summary       = 'Collection of useful modules for Rails'
  spec.homepage      = 'https://github.com/printercu/rails_stuff'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'sdoc', '~> 0.4.1'
  spec.add_development_dependency 'pry', '~> 0.10.1'

  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'rspec-its', '~> 1.1.0'

  spec.add_development_dependency 'rubocop', '~> 0.33.0'
end
