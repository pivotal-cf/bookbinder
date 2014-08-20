class Vienna::Application
  def initialize(root = 'public')
    @app = Rack::Builder.new do
      use Rack::Static, {
        urls: Dir.glob("#{root}/**/*").map { |fn| fn.gsub(/^#{root}/, '')},
        root: root,
        index: 'index.html',
        header_rules: [[:all, {'Cache-Control' => 'public, max-age=3600'}]]
      }
      run Vienna::NotFound.new("#{root}/404.html")
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
