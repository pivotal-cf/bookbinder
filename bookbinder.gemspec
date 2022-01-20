require 'base64'

Gem::Specification.new do |s|
  s.name        = 'bookbindery'
  s.version     = '10.1.17'
  s.summary     = 'Markdown to Rackup application documentation generator'
  s.description = 'A command line utility to be run in Book repositories to stitch together their constituent Markdown repos into a static-HTML-serving application'
  s.authors     = ['Mike Grafton', 'Lucas Marks', 'Gavin Morgan', 'Nikhil Gajwani', 'Dan Wendorf', 'Brenda Chan', 'Matthew Boedicker', 'Andrew Bruce', 'Frank Kotsianas', 'Elena Sharma', 'Christa Hartsock', 'Michael Trestman', 'Alpha Chen', 'Sarah McAlear', 'Gregg Van Hove', 'Jess B Heron', "Rajan Agaskar"]
  s.email       = Base64.decode64('Z21vcmdhbkBnb3Bpdm90YWwuY29t') # Gavin's

  s.files       = Dir['lib/**/*'] + Dir['template_app/**/*'] + Dir['master_middleman/**/*'] + Dir['install_bin/bookbinder'] + Dir['bookbinder.gemspec']
  s.homepage    = 'https://github.com/pivotal-cf/bookbinder'
  s.license     = 'MIT'
  s.bindir      = 'install_bin'
  s.executable  = 'bookbinder'

  s.required_ruby_version = '>= 2.3.3'
  s.add_runtime_dependency 'fog-aws', ['~> 0.7.1']
  s.add_runtime_dependency 'ansi', ['~> 1.4']
  s.add_runtime_dependency 'middleman', ['4.1.10']
  s.add_runtime_dependency 'middleman-livereload'
  s.add_runtime_dependency 'middleman-syntax', ['2.1.0']
  s.add_runtime_dependency 'rouge', '!= 1.9.1'
  s.add_runtime_dependency 'redcarpet', ['~> 3.2.3']
  s.add_runtime_dependency 'css_parser'
  s.add_runtime_dependency 'puma'
  s.add_runtime_dependency 'rack-rewrite'
  s.add_runtime_dependency 'git', '~> 1.2.8'
  s.add_runtime_dependency 'nokogiri', ['1.10.1']
  s.add_runtime_dependency 'thor', ['0.19.1']
  s.add_runtime_dependency 'elasticsearch'
  s.add_runtime_dependency 'font-awesome-sass', ['4.7.0']
  s.add_runtime_dependency 'middleman-sprockets'
  s.add_runtime_dependency 'middleman-compass'
  s.add_runtime_dependency 'sprockets', '3.7.2'

  s.add_development_dependency 'license_finder'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sendgrid-ruby', '< 3.0'
  s.add_development_dependency 'sinatra', '1.4.8'
  s.add_development_dependency 'jasmine'
  s.add_development_dependency 'rack-test'
end
