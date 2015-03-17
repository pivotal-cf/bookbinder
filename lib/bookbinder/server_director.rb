require 'puma'
require 'rack/rewrite'
require 'vienna'

module Bookbinder
  class ServerDirector
    def initialize(logger, directory: nil, port: 41722)
      @logger = logger
      @directory = directory
      @port = port
    end

    def use_server
      Dir.chdir(@directory) do
        result = nil
        events = Puma::Events.new $stdout, $stderr
        server = Puma::Server.new app, events
        server.add_tcp_listener "localhost", @port
        server.run
        begin
          result = yield @port
        ensure
          server.stop(true)
        end
        result
      end
    end

    private

    def app
      if File.exists?('redirects.rb')
        Rack::Rewrite.new(Vienna) { eval(File.read('redirects.rb')) }
      else
        Vienna
      end
    end
  end
end
