require 'sinatra'

if ARGV[0]
  set :port, ARGV[0]
end

use Rack::Static, :urls => [''], :index => 'index.html', :root => 'public'