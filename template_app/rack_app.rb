require 'rack/rewrite'
require 'rack/auth/basic'
require 'vienna'

module Bookbinder
  class RackApp
    def initialize(redirect_pathname, auth_required: true)
      @redirect_pathname = redirect_pathname
      @auth_required = auth_required
    end

    def app
      app = resolve_redirects

      if auth_required && site_username && site_password
        authorize_user(app)
      else
        app
      end
    end

    private

    attr_reader :redirect_pathname, :auth_required

    def resolve_redirects
      if redirect_pathname.exist?
        p = redirect_pathname
        Rack::Rewrite.new(Vienna) { eval(p.read) }
      else
        Vienna
      end
    end

    def authorize_user(app)
      Rack::Auth::Basic.new(app) do |username, password|
        [username, password] == [site_username, site_password]
      end
    end

    def site_username
      ENV['SITE_AUTH_USERNAME']
    end

    def site_password
      ENV['SITE_AUTH_PASSWORD']
    end
  end
end
