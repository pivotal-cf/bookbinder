require 'base64'

Gem::Specification.new do |s|
  s.name        = 'bookbindery'
  s.version     = '1.0.3'
  s.summary     = 'Markdown to Rackup application documentation generator'
  s.description = 'A command line utility to be run in Book repositories to stitch together their constituent Markdown repos into a static-HTML-serving application'
  s.authors     = ['Mike Grafton', 'Lucas Marks', 'Gavin Morgan', 'Nikhil Gajwani', 'Dan Wendorf', 'Brenda Chan', 'Matthew Boedicker', 'Frank Kotsianas']
  s.email       = Base64.decode64('Z21vcmdhbkBnb3Bpdm90YWwuY29t') # Gavin's

  s.files       = Dir['lib/**/*'] + Dir['template_app/**/*'] + Dir['master_middleman/**/*'] + Dir['install_bin/**/*']
  s.homepage    = 'https://github.com/cloudfoundry-incubator/bookbinder'
  s.license     = 'MIT'
  s.bindir      = 'install_bin'
  s.executable  = 'bookbinder'

  s.add_runtime_dependency 'fog-aws', ['~> 0.0.6']
  s.add_runtime_dependency 'octokit', ['2.7.0']
  s.add_runtime_dependency 'ansi', ['~> 1.4']
  s.add_runtime_dependency 'unf', ['~> 0.1']
  s.add_runtime_dependency 'middleman', ['~> 3.3.5']
  s.add_runtime_dependency 'middleman-syntax', ['~> 2.0']
  s.add_runtime_dependency 'redcarpet', ['~> 3.0']
  s.add_runtime_dependency 'vienna', ['= 0.4.0']
  s.add_runtime_dependency 'wkhtmltopdf-binary-cf', ['= 0.12.3']
  s.add_runtime_dependency 'anemone'
  s.add_runtime_dependency 'css_parser'
  s.add_runtime_dependency 'puma'
  s.add_runtime_dependency 'popen4'
  s.add_runtime_dependency 'rack-rewrite'
  s.add_runtime_dependency 'therubyracer'
  s.add_runtime_dependency 'git', '~> 1.2.8'

  s.add_development_dependency 'license_finder'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
