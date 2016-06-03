require 'rack'
require 'rack/rewrite'
require_relative './lib/server'
require_relative './lib/search/handler'

module Bookbinder
  class RackApp
    def initialize(redirect_pathname, mail_client=nil, auth_required: true)
      @redirect_pathname = redirect_pathname
      @mail_client = mail_client
      @auth_required = auth_required
    end

    def app
      path = redirect_pathname
      client = mail_client
      auth = auth_required
      Rack::Builder.new do
        use ResolveRedirects, path
        use AuthorizeUser, auth
        use Rack::Deflater
        map '/api/feedback' do
          use MailFeedback, client
          run Bookbinder::NotFound.new('public/404.html')
        end
        map '/search' do
          run Bookbinder::Search::Handler.new
        end
        run Bookbinder::Server
      end
    end

    private

    attr_reader :redirect_pathname, :mail_client, :auth_required
  end

  class ResolveRedirects
    def initialize(app, redirect_pathname)
      @app = app
      @redirect_pathname = redirect_pathname
    end

    def rack_app
      if redirect_pathname.exist?
        p = redirect_pathname
        Rack::Rewrite.new(@app) { eval(p.read) }
      else
        @app
      end
    end

    def call(env)
      rack_app.call(env)
    end

    private

    attr_reader :redirect_pathname
  end

  class AuthorizeUser
    def initialize(app, auth_required)
      @app = app
      @auth_required = auth_required
    end

    def rack_app
      if auth_required && site_username && site_password
        Rack::Auth::Basic.new(@app) do |username, password|
          [username, password] == [site_username, site_password]
        end
      else
        @app
      end
    end

    def call(env)
      rack_app.call(env)
    end

    private

    attr_accessor :auth_required

    def site_username
      ENV['SITE_AUTH_USERNAME']
    end

    def site_password
      ENV['SITE_AUTH_PASSWORD']
    end
  end

  class MailFeedback
    def initialize(app, client)
      @app = app
      @client = client
    end

    def call(env)
      request = Rack::Request.new(env)
      if request.post? && @client
        @client.send_mail(request.params)
      else
        @app.call(env)
      end
    end
  end
end
