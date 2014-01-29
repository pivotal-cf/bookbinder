Gem::Specification.new do |s|
  s.name        = 'bookbinder'
  s.version     = '0.0.9'
  s.summary     = 'Markdown to Sinatra application documentation generator'
  s.description = 'A command line utility to be run in Book repositories to stitch together their constituent Markdown repos into a static-HTML-serving application'
  s.authors     = ['Mike Grafton', 'Lucas Marks', 'Gavin Morgan', 'Nikhil Gajwani']
  s.email       = 'gmorgan@gopivotal.com'
  s.files =     Dir['lib/**/*'] + Dir['template_app/**/*'] + Dir['master_middleman/**/*'] + Dir['bin/**/*']
  s.homepage    =
    'https://github.com/pivotal-cf/docs-bookbinder'
  s.license       = 'MIT'
  s.executable = 'bookbinder'

  s.add_runtime_dependency 'fog', ['~> 1.17']
  s.add_runtime_dependency 'octokit', ['2.7.0']
  s.add_runtime_dependency 'ansi', ['~> 1.4']
  s.add_runtime_dependency 'unf', ['~> 0.1']
  s.add_runtime_dependency 'middleman', ['3.2.1']
  s.add_runtime_dependency 'redcarpet', ['~> 3.0']
  s.add_runtime_dependency 'sinatra', ['~> 1.4']
  s.add_runtime_dependency 'wkhtmltopdf-binary', ['~> 0.9.9']
  s.add_runtime_dependency 'faraday', ['~> 0.8.8']
  s.add_runtime_dependency 'faraday_middleware', ['~> 0.9.0']
end
