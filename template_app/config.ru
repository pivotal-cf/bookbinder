require 'vienna'

if File.exists?('redirects.rb')
  require 'rack/rewrite'
  use(Rack::Rewrite) { eval File.read('redirects.rb') }
end

require_relative 'lib/vienna_application'
require_relative 'lib/rack_static'

run Vienna
