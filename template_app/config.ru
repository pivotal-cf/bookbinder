require 'vienna'

use Rack::Auth::Basic, 'PCFP Docs' do |username, password|
    username = 'pcf', password = 'docs'
end

if File.exists?('redirects.rb')
  require 'rack/rewrite'
  use(Rack::Rewrite) { eval File.read('redirects.rb') }
end

require './app'
run Vienna
