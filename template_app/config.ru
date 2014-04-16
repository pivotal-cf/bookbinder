require 'vienna'

if File.exists?('redirects.rb')
  require 'rack/rewrite'
  use(Rack::Rewrite) { eval File.read('redirects.rb') }
end

require './app'
run Vienna
