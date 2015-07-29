require 'rack/rewrite'
require 'vienna'

module Bookbinder
  class RackApp
    def initialize(redirect_pathname)
      @redirect_pathname = redirect_pathname
    end

    def app
      if redirect_pathname.exist?
        p = redirect_pathname
        Rack::Rewrite.new(Vienna) { eval(p.read) }
      else
        Vienna
      end
    end

    private

    attr_reader :redirect_pathname
  end
end
