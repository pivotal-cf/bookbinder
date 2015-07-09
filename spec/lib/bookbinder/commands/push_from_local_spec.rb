require_relative '../../../helpers/nil_logger'
require_relative '../../../../lib/bookbinder/commands/push_from_local'
require_relative '../../../../lib/bookbinder/config/aws_credentials'
require_relative '../../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Commands
    describe PushFromLocal do
      let(:book_repo) { 'my-user/fixture-book-title' }
      let(:config_hash) { {'book_repo' => book_repo, 'cred_repo' => 'whatever'} }
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
