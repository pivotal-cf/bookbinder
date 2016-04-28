require_relative './rack_static_if_exists'

module Bookbinder
  class Server
    class << self
      def call(env)
        Bookbinder::Server.new.call(env)
      end
    end

    def initialize
      @app = Rack::Builder.new do
        use RackStaticIfExists, {
          urls: [''],
          root: 'public',
          index: 'index.html',
          header_rules: [[:all, {
            'Cache-Control' => 'public, max-age=3600',
            'Access-Control-Allow-Origin' => '*'
          }]]
        }
        run Bookbinder::NotFound.new("public/404.html")
      end
    end

    def call(env)
      if env['PATH_INFO'] == '' || env['PATH_INFO'] =~ MATCH || (env['PATH_INFO'] !~ /\/$/ && File.directory?(File.join('public', env['PATH_INFO'])))
        env['PATH_INFO'] += '/'
        [301, {'Location' => Rack::Request.new(env).url, 'Content-Type' => ''}, []]
      else
        @app.call(env)
      end
    end

    private
    # regexp to match strings without periods that start but don't end with a slash
    MATCH = %r{^/([^.]+)[^/]$}
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
