require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'
require_relative '../../../../lib/bookbinder/commands/push_from_local'
require_relative '../../../../lib/bookbinder/config/aws_credentials'
require_relative '../../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../../lib/bookbinder/config/configuration'
require_relative '../../../../lib/bookbinder/remote_yaml_credential_provider'

module Bookbinder
  module Commands
    describe PushFromLocal do
      include SpecHelperMethods

      let(:book_repo) { 'my-user/fixture-book-title' }
      let(:config_hash) { {'book_repo' => book_repo, 'cred_repo' => 'whatever'} }

      let(:fake_distributor) { double(Distributor, distribute: nil) }

      let(:logger) { NilLogger.new }
      let(:configuration_fetcher) { double('configuration_fetcher') }
      let(:config) { Config::Configuration.parse(config_hash) }
      let(:command) { PushFromLocal.new(logger, configuration_fetcher, 'foobar_env') }
      let(:credentials) {
        {
          aws: Config::AwsCredentials.new(
            'access_key' => 'your_aws_access_key',
            'secret_key' => 'your_aws_secret_key',
            'green_builds_bucket' => 'your_aws_bucket'
          ),
          cloud_foundry: Config::CfCredentials.new({
            'username' => 'your_CF_account',
            'password' => 'your_CF_password',
            'app_name' => 'your_app_name',
            'api_endpoint' => 'your_api_endpoint',
            'organization' => 'your_organization'
          }, 'foobar_env')
        }
      }

      it 'returns 0' do
        allow(Distributor).to receive(:build).and_return(fake_distributor)
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
        allow(configuration_fetcher).to receive(:fetch_credentials).
          with('foobar_env').
          and_return(credentials)

        expect(command.run([])).to eq(0)
      end

      context 'happy path' do
        let(:credentials) {
          {
            aws: Config::AwsCredentials.new(
              'access_key' => 'your_aws_access_key',
              'secret_key' => 'your_aws_secret_key',
              'green_builds_bucket' => 'your_aws_bucket'
            ),
            cloud_foundry: Config::CfCredentials.new({
              'username' => 'your_CF_account',
              'password' => 'your_CF_password',
              'app_name' => 'your_app_name',
              'api_endpoint' => 'your_api_endpoint',
              'organization' => 'your_organization',
              'foobar_env_host' => { 'domain-one.io' => ['docs'] }
            }, 'foobar_env')
          }
        }
        it 'builds a distributor with the right options and asks it to distribute' do
          expected_options = {
            app_dir: './final_app',
            build_number: nil,

            aws_credentials: credentials[:aws],
            cf_credentials: credentials[:cloud_foundry],

            book_repo: book_repo,
          }

          allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
          allow(configuration_fetcher).to receive(:fetch_credentials).
            with('foobar_env').
            and_return(credentials)

          real_distributor = expect_to_receive_and_return_real_now(
            Distributor, :build, logger, expected_options
          )
          expect(real_distributor).to receive(:distribute)

          command.run([])
        end
      end

      describe 'missing keys in the config' do
        context 'when required platform names are missing' do
          let(:credentials) {
            {
              aws: Config::AwsCredentials.new({}),
              cloud_foundry: Config::CfCredentials.new({}, 'foobar_env')
            }
          }
          it 'raises an informative error' do
            allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
            allow(configuration_fetcher).to receive(:fetch_credentials).
              with('foobar_env').
              and_return(credentials)

            expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
          end
        end

        context 'when required platform names are present' do
          let(:credentials) {
            {
              aws: Config::AwsCredentials.new({}),
              cloud_foundry: Config::CfCredentials.new({
                'username' => 'your_CF_account',
                'password' => 'your_CF_password',
                'app_name' => 'your_app_name',
                'api_endpoint' => 'your_api_endpoint',
                'organization' => 'your_organization'
              }, 'foobar_env')
            }
          }
          context 'and aws credential keys are missing' do
            it 'raises an informative error' do
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
              allow(configuration_fetcher).to receive(:fetch_credentials).
                with('foobar_env').
                and_return(credentials)

              expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
            end
          end

          context 'when cloud foundry credential keys are missing' do
            let(:credentials) {
              {
                aws: Config::AwsCredentials.new('access_key' => 'your_aws_access_key',
                                                'secret_key' => 'your_aws_secret_key',
                                                'green_builds_bucket' => 'your_aws_bucket'),
                cloud_foundry: Config::CfCredentials.new({}, 'foobar_env')
              }
            }
            it 'raises an informative error' do
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
              allow(configuration_fetcher).to receive(:fetch_credentials).
                with('foobar_env').
                and_return(credentials)

              expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
            end
          end
        end
      end

    end
  end
end
