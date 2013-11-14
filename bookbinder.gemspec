Gem::Specification.new do |s|
  s.name        = 'bookbinder'
  s.version     = '0.0.1'
  s.date        = '2013-11-07'
  s.summary     = 'Documentation generator for Cloud Foundry'
  s.description = 'Documentation generator for Cloud Foundry'
  s.authors     = ['Mike Grafton', 'Lucas Marks']
  s.email       = 'mike@pivotallabs.com'
  s.files =     Dir['lib/**/*'] + Dir['template_app/**/*'] + Dir['master_middleman/**/*'] + Dir['bin/*']
  s.homepage    =
    'http://github.com/cloudfoundry/bookbinder'
  s.license       = 'MIT'
  s.executable = 'bookbinder'

  s.add_runtime_dependency 'fog', ['~> 1.17']
  s.add_runtime_dependency 'ansi', ['~> 1.4']
  s.add_runtime_dependency 'httparty', ['~> 0.12']
  s.add_runtime_dependency 'unf', ['~> 0.1']
  s.add_runtime_dependency 'middleman', ['~> 3.1']
  s.add_runtime_dependency 'redcarpet', ['~> 3.0']
  s.add_runtime_dependency 'sinatra', ['~> 1.4']
  s.add_runtime_dependency 'wkhtmltopdf-binary', ['~> 0.9.9']
end
