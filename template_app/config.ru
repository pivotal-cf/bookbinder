require 'pathname'
require 'vienna'
require './rack_app'
require './app'
run Bookbinder::RackApp.new(Pathname('redirects.rb')).app
