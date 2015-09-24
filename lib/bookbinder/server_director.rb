require 'puma'

module Bookbinder
  class ServerDirector
    def initialize(app: nil, directory: nil, port: 41722)
      @app = app
      @directory = directory
      @port = port
    end

    def use_server
      Dir.chdir(@directory) do
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

    attr_reader :app
  end
end
