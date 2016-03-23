require_relative './rack_static'

module Bookbinder
  module Vienna
    class << self
      def call(env)
        Application.new.call(env)
      end
    end

    class Application
      def initialize
        @app = Rack::Builder.new do
          use RackStatic, {
              urls: Dir.glob("public/**/*").map { |path| path.sub(/^public/, '')},
              root: 'public',
              index: 'index.html',
              header_rules: [[:all, {
                'Cache-Control' => 'public, max-age=3600',
                'Access-Control-Allow-Origin' => '*'
              }]]
            }
          run NotFound.new("public/404.html")
        end
      end

      def call(env)
        if env['PATH_INFO'] != '/' && env['PATH_INFO'] =~ MATCH
          env['PATH_INFO'] += '/'
          [301, {'Location' => Rack::Request.new(env).url, 'Content-Type' => ''}, []]
        else
          @app.call(env)
        end
      end

      private
      # regexp to match strings without periods that start and end with a slash
      MATCH = %r{^/([^.]*)[^/]$}
    end

    class NotFound
      def initialize(path = '')
        @path = path
      end

      def call(env)
        content = File.exist?(@path) ? File.read(@path) : 'Not Found'
        length = content.length.to_s

        [404, {'Content-Type' => 'text/html', 'Content-Length' => length}, [content]]
      end
    end
  end
end
