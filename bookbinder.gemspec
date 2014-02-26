require 'base64'

Gem::Specification.new do |s|
  s.name        = 'bookbinder'
  s.version     = '0.1.7'
  s.summary     = 'Markdown to Rackup application documentation generator'
  s.description = 'A command line utility to be run in Book repositories to stitch together their constituent Markdown repos into a static-HTML-serving application'
  s.authors     = ['Mike Grafton', 'Lucas Marks', 'Gavin Morgan', 'Nikhil Gajwani', 'Dan Wendorf']
  s.email       = Base64.decode64('Z21vcmdhbkBnb3Bpdm90YWwuY29t') # Gavin's

  s.files       = Dir['lib/**/*'] + Dir['template_app/**/*'] + Dir['master_middleman/**/*'] + Dir['bin/**/*']
  s.homepage    = 'https://github.com/pivotal-cf/docs-bookbinder'
  s.license     = 'MIT'
  s.executable  = 'bookbinder'

  s.add_runtime_dependency 'fog', ['~> 1.17']
  s.add_runtime_dependency 'octokit', ['2.7.0']
  s.add_runtime_dependency 'ansi', ['~> 1.4']
  s.add_runtime_dependency 'unf', ['~> 0.1']
  s.add_runtime_dependency 'middleman', ['3.2.1']
  s.add_runtime_dependency 'redcarpet', ['~> 3.0']
  s.add_runtime_dependency 'vienna', ['= 0.4.0']
  s.add_runtime_dependency 'thin'
  s.add_runtime_dependency 'wkhtmltopdf-binary', ['~> 0.9.9']
  s.add_runtime_dependency 'faraday', ['~> 0.8.8']
  s.add_runtime_dependency 'faraday_middleware', ['~> 0.9.0']
  s.add_runtime_dependency 'anemone'
  s.add_runtime_dependency 'css_parser'
  s.add_runtime_dependency 'open4'
end
