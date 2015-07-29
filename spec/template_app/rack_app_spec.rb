require 'net/http'
require 'rack/test'
require_relative '../../template_app/rack_app'

module Bookbinder
  describe RackApp do
    include Rack::Test::Methods

    it 'respects a redirects file' do
      redirects = instance_double(
        'Pathname',
        read: "r301 '/index.html', '/dogs/index.html'",
        exist?: true
      )
      app = RackApp.new(redirects).app
      session = Rack::Test::Session.new(app)

      session.get('/index.html')

      expect(session.last_response.status).to eq(301)
    end

    it 'works without one' do
      redirects = instance_double(
        'Pathname',
        exist?: false
      )
      app = RackApp.new(redirects).app
      session = Rack::Test::Session.new(app)

      session.get('/index.html')

      expect(session.last_response.status).to eq(404)
    end
  end
end
