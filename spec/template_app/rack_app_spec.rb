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

    describe 'sending feedback' do
      let(:redirects) { instance_double('Pathname', exist?: false) }
      let(:mail_client) { double('mail client') }

      it 'responds to post at endpoint and returns its response' do
        response = [201, {}, 'Creation!']

        app = RackApp.new(redirects, mail_client).app
        session = Rack::Test::Session.new(app)

        expect(mail_client).to receive(:send_mail).
            with({'helpful' => 'yes',
                 'comments' => 'I love it',
                 'date' => 'the future',
                 'page_url' => 'the page'}) { response }

        session.post('/api/feedback', {helpful:'yes', comments:'I love it', date:'the future', page_url:'the page'})

        expect(session.last_response.status).to eq(201)
      end

      it 'responds with a 404 to a get at endpoint' do
        app = RackApp.new(redirects, mail_client).app
        session = Rack::Test::Session.new(app)

        session.get('/api/feedback')

        expect(session.last_response.status).to eq(404)
      end

      it 'responds with 404 to post if mail_client is not provided' do
        app = RackApp.new(redirects).app
        session = Rack::Test::Session.new(app)

        session.post('/api/feedback', {helpful:'yes', comments:'I love it', date:'the future', page_url:'the page'})

        expect(session.last_response.status).to eq(404)
      end
    end

    describe 'authorization' do
      let(:redirects) { instance_double('Pathname', exist?: false) }

      context 'when username and password are specified as env variables' do
        it 'requires a username and password by default' do
          begin
            ENV['SITE_AUTH_USERNAME'] = 'claud'
            ENV['SITE_AUTH_PASSWORD'] = 'fawndry'

            app = RackApp.new(redirects).app
            session = Rack::Test::Session.new(app)

            session.get('/index.html')

            expect(session.last_response.status).to eq(401)
          ensure
            ENV['SITE_AUTH_USERNAME'] = nil
            ENV['SITE_AUTH_PASSWORD'] = nil
          end
        end

        it 'sets env variables as the username and password' do
          begin
            ENV['SITE_AUTH_USERNAME'] = 'claud'
            ENV['SITE_AUTH_PASSWORD'] = 'fawndry'

            app = RackApp.new(redirects).app
            session = Rack::Test::Session.new(app)

            session.basic_authorize('claud','fawndry')
            session.get('/index.html')

            expect(session.last_response.status).to_not eq(401)
          ensure
            ENV['SITE_AUTH_USERNAME'] = nil
            ENV['SITE_AUTH_PASSWORD'] = nil
          end
        end

        it 'allows bypass of username and password' do
          begin
            ENV['SITE_AUTH_USERNAME'] = 'claud'
            ENV['SITE_AUTH_PASSWORD'] = 'fawndry'

            app = RackApp.new(redirects, auth_required: false).app
            session = Rack::Test::Session.new(app)

            session.get('/index.html')

            expect(session.last_response.status).to_not eq(401)
          ensure
            ENV['SITE_AUTH_USERNAME'] = nil
            ENV['SITE_AUTH_PASSWORD'] = nil
          end
        end
      end

      context 'when neither username nor password are specified' do
        it 'does not require a username and password' do
          app = RackApp.new(redirects).app
          session = Rack::Test::Session.new(app)

          session.get('/index.html')

          expect(session.last_response.status).to_not eq(401)
        end
      end
    end
  end
end
