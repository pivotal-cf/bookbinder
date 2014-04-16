require 'vienna'

if File.exists?('redirects')
  require 'rack/rewrite'
  use(Rack::Rewrite) { eval File.read('redirects') }
end

require './app'
run Vienna
