require 'pathname'
require './rack_app'

run Bookbinder::RackApp.new(Pathname('redirects.rb')).app
