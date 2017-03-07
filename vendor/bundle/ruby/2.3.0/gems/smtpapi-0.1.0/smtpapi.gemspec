# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smtpapi/version'

Gem::Specification.new do |spec|
  spec.name          = 'smtpapi'
  spec.version       = Smtpapi::VERSION
  spec.authors       = ['Wataru Sato', 'SendGrid']
  spec.email         = ['awwa500@gmail.com', 'community@sendgrid.com']
  spec.summary       = 'Smtpapi library for SendGrid.'
  spec.description   = 'Smtpapi library for SendGrid.'
  spec.homepage      = 'https://github.com/sendgrid/smtpapi-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency('rubocop', '>=0.29.0', '<0.30.0')
  spec.add_development_dependency('test-unit', '~> 3.0')
end
