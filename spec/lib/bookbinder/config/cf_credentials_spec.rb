require_relative '../../../../lib/bookbinder/config/cf_credentials'

module Bookbinder
  module Config
    describe CfCredentials do
      let(:environment) { 'staging' }
      let(:cf_staging_routes) {{ 'some-staging-domain.io' => ['some-staging-host'] }}
      let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host'] }}
      let(:cf_hash) do
        {
            'api_endpoint' => 'http://some-api-endpoint.example.com',
            'staging_host' => cf_staging_routes,
            'production_space' => 'some-prod-space',
            'production_host' => cf_prod_routes,
            'staging_space' => 'some-staging-space',
            'app_name' => 'some-app',
            'username' => 'some-user',
            'password' => 'some-pass',
            'organization' => 'some-org'
        }
      end
      let(:cf_credentials) { CfCredentials.new(cf_hash, environment) }

      it 'returns a Configuration with the CF credentials from the credentials repository' do
        expect(cf_credentials.api_endpoint).to eq('http://some-api-endpoint.example.com')
        expect(cf_credentials.app_name).to eq('some-app')
        expect(cf_credentials.username).to eq('some-user')
        expect(cf_credentials.password).to eq('some-pass')
        expect(cf_credentials.organization).to eq('some-org')
      end

      it 'memoizes' do
        expect(cf_credentials).to be(cf_credentials)
      end

      describe 'default values' do
        it 'defaults username to nil' do
          cf_hash.delete('username')
          expect(cf_credentials.username).to be_nil
        end

        it 'defaults password to nil' do
          cf_hash.delete('password')
          expect(cf_credentials.password).to be_nil
        end
      end

      describe 'environment' do
        context 'when production' do
          let(:environment) { 'production' }

          it 'uses production values for host and space' do
            expect(cf_credentials.routes).to eq('some-prod-domain.io'=>['some-prod-host'])
            expect(cf_credentials.space).to eq('some-prod-space')
          end
        end

        context 'when staging' do
          let(:environment) { 'staging' }

          it 'uses staging values for host and space' do
            expect(cf_credentials.routes).to eq('some-staging-domain.io'=>['some-staging-host'])
            expect(cf_credentials.space).to eq('some-staging-space')
          end
        end
      end

      describe '#routes' do
        let(:environment) { 'production' }

        context 'with a correctly formatted domain' do
          let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host'] }}
          it 'succeeds' do
            expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host'])
          end
        end

        context 'with multiple correctly formatted domains' do
          let(:cf_prod_routes) do
            {
                'some-prod-domain.io' => ['some-prod-host'],
                'another-prod-domain.io' => ['another-prod-host, yet-a-third-prod-host']
            }
          end
          it 'succeeds' do
            expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host'],
                                                'another-prod-domain.io' => ['another-prod-host, yet-a-third-prod-host'])
          end
        end

        context 'when domains are incorrectly formatted' do
          context 'and domains are given as an array' do
            let(:cf_prod_routes) {{ ['some-prod-domain.io', 'another-prod-domain.io'] => ['some-prod-host'] }}
            it 'raises' do
              expect { cf_credentials.routes }.to raise_error(/Each domain in credentials must be a single string./)
            end
          end

          context 'and a domain is given without an extension' do
            let(:cf_prod_routes) {{ 'some-prod-domain' => ['some-prod-host'] }}
            it 'raises' do
              expect { cf_credentials.routes }.to raise_error(/must contain a web extension/)
            end
          end
        end

        context 'with correctly formatted routes' do
          let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host', 'another-prod-host'] }}

          it 'succeeds' do
            expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host', 'another-prod-host'])
          end
        end

        context 'with incorrectly formatted routes' do
          let(:cf_prod_routes) {{ 'some-prod-domain.io' => 'some-prod-host' }}

          it 'raises' do
            expect { cf_credentials.routes }.to raise_error(/Hosts in credentials must be nested as an array/)
          end
        end

        context 'when all hosts for a domain are nil' do
          let(:cf_prod_routes) {{ 'some-prod-domain.io' => nil }}

          it 'raises' do
            expect { cf_credentials.routes }.to raise_error(/Did you mean to add a list of hosts for domain some-prod-domain.io/)
          end
        end

        context 'when a host is nil' do
          let(:cf_prod_routes) {{ 'some-prod-domain.io' => [nil] }}

          it 'raises' do
            expect { cf_credentials.routes }.to raise_error(/Did you mean to provide a hostname for the domain some-prod-domain.io/)
          end
        end
      end
    end
  end
end

