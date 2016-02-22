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
      let(:command) { PushFromLocal.new(streams = {}, logger, configuration_fetcher) }
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
            'app_name' => 'your_app_nam\e',
            'api_endpoint' => 'your_api_endpoint',
            'organization' => 'your_organization',
            'env' => {
              'foobar_env' => {
                'host' => {}
              }
            }
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

            expect { command.run(['foobar_env']) }.to raise_error PushFromLocal::CredentialKeyError
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

              expect { command.run(['foobar_env']) }.to raise_error PushFromLocal::CredentialKeyError
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

              expect { command.run(['foobar_env']) }.to raise_error PushFromLocal::CredentialKeyError
            end
          end
        end
      end

      describe 'feedback configuration' do
        context 'when feedback is enabled' do
          let(:config_hash){ {'feedback_enabled' => true, 'book_repo' => 'my/repo'} }

          it 'raises an error if sendgrid username and api key not provided' do
            creds = [ENV['SENDGRID_USERNAME'], ENV['SENDGRID_API_KEY']]

            begin
              ENV['SENDGRID_USERNAME'], ENV['SENDGRID_API_KEY'] = nil, nil

              allow(configuration_fetcher).to receive(:fetch_credentials).and_return(credentials)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              expect { command.run([]) }.to raise_error PushFromLocal::FeedbackConfigError
            ensure
              ENV['SENDGRID_USERNAME'], ENV['SENDGRID_API_KEY'] = creds
            end
          end

          it 'raises an error if feedback enabled without to and from addresses' do
            mail_config = [ENV['FEEDBACK_TO'], ENV['FEEDBACK_FROM']]

            begin
              ENV['FEEDBACK_TO'], ENV['FEEDBACK_FROM'] = nil, nil

              allow(configuration_fetcher).to receive(:fetch_credentials).and_return(credentials)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              expect { command.run([]) }.to raise_error PushFromLocal::FeedbackConfigError
            ensure
              ENV['FEEDBACK_TO'], ENV['FEEDBACK_FROM'] = mail_config
            end
          end

          it 'succeeds if feedback enabled and all config is present' do
            mail_config = [ENV['SENDGRID_USERNAME'],
                      ENV['SENDGRID_API_KEY'],
                      ENV['FEEDBACK_TO'],
                      ENV['FEEDBACK_FROM']]

            begin
              ENV['SENDGRID_USERNAME'] = 'the sea'
              ENV['SENDGRID_API_KEY'] = 'key'
              ENV['FEEDBACK_TO'] = 'a_tree@mail.com'
              ENV['FEEDBACK_FROM'] = 'the_sea@mail.com'

              allow(configuration_fetcher).to receive(:fetch_credentials).and_return(credentials)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              allow(Deploy::Deployment).to receive(:new) { double('dep').as_null_object }
              allow(Deploy::Archive).to receive(:new) { double('archive') }
              allow(Deploy::Distributor).to receive(:build) { double('built deployment').as_null_object }

              expect { command.run([]) }.to_not raise_error
            ensure
              ENV['SENDGRID_USERNAME'],
              ENV['SENDGRID_API_KEY'],
              ENV['FEEDBACK_TO'],
              ENV['FEEDBACK_FROM'] = mail_config
            end
          end
        end

        context 'when feedback is not enabled' do
          it 'succeeds without any credentials' do
            mail_config = [ENV['SENDGRID_USERNAME'],
              ENV['SENDGRID_API_KEY'],
              ENV['FEEDBACK_TO'],
              ENV['FEEDBACK_FROM']]

            begin
              ENV['SENDGRID_USERNAME'] = nil
              ENV['SENDGRID_API_KEY'] = nil
              ENV['FEEDBACK_TO'] = nil
              ENV['FEEDBACK_FROM'] = nil

              allow(configuration_fetcher).to receive(:fetch_credentials).and_return(credentials)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              allow(Deploy::Deployment).to receive(:new) { double('dep').as_null_object }
              allow(Deploy::Archive).to receive(:new) { double('archive') }
              allow(Deploy::Distributor).to receive(:build) { double('built deployment').as_null_object }

              expect { command.run([]) }.to_not raise_error
            ensure
              ENV['SENDGRID_USERNAME'],
                ENV['SENDGRID_API_KEY'],
                ENV['FEEDBACK_TO'],
                ENV['FEEDBACK_FROM'] = mail_config
            end
          end
        end
      end
    end
  end
end
