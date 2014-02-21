exec("rackup -p #{ARGV[0] || 4567}") if require('vienna')
require_relative 'lib/vienna_application'
require_relative 'lib/rack_static'
