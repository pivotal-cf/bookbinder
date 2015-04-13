require_relative '../../../../lib/bookbinder/commands/push_from_local'
require_relative '../../../../lib/bookbinder/configuration'
require_relative '../../../../lib/bookbinder/remote_yaml_credential_provider'
require_relative '../../../helpers/middleman'
require_relative '../../../helpers/nil_logger'

module Bookbinder
  module Commands
    describe PushFromLocal do
      include SpecHelperMethods

      let(:book_repo) { 'my-user/fixture-book-title' }
      let(:config_hash) { {'book_repo' => book_repo, 'cred_repo' => 'whatever'} }

      let(:fake_distributor) { double(Distributor, distribute: nil) }

      let(:options) do
        {
          app_dir: './final_app',
          build_number: nil,

          aws_credentials: config.aws_credentials,
          cf_credentials: config.cf_credentials('foobar_env'),

          book_repo: book_repo,
        }
      end

      let(:logger) { NilLogger.new }
      let(:configuration_fetcher) { double('configuration_fetcher') }
      let(:config) { Configuration.new(logger, config_hash) }
      let(:command) { PushFromLocal.new(logger, configuration_fetcher, 'foobar_env') }

      it 'returns 0' do
        fake_cred_repo = double(RemoteYamlCredentialProvider,
                                credentials: {
                                    'aws' => {
                                        'access_key' => 'your_aws_access_key',
                                        'secret_key' => 'your_aws_secret_key',
                                        'green_builds_bucket' => 'your_aws_bucket'
                                    },
                                    'cloud_foundry' => {
                                        'username' => 'your_CF_account',
                                        'password' => 'your_CF_password',
                                        'app_name' => 'your_app_name',
                                        'api_endpoint' => 'your_api_endpoint',
                                        'organization' => 'your_organization'
                                    }
                                })
        allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)

        allow(Distributor).to receive(:build).and_return(fake_distributor)
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        expect(command.run([])).to eq(0)
      end

      it 'builds a distributor with the right options and asks it to distribute' do
        fake_cred_repo = double(RemoteYamlCredentialProvider,
                                credentials: {
                                    'aws' => {
                                        'access_key' => 'your_aws_access_key',
                                        'secret_key' => 'your_aws_secret_key',
                                        'green_builds_bucket' => 'your_aws_bucket'
                                    },
                                    'cloud_foundry' => {
                                        'username' => 'your_CF_account',
                                        'password' => 'your_CF_password',
                                        'app_name' => 'your_app_name',
                                        'api_endpoint' => 'your_api_endpoint',
                                        'organization' => 'your_organization',
                                        'foobar_env_host' => {
                                            'foodomain.com' =>
                                              ['bar']
                                        }
                                    }
                                })
        allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)
        allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

        real_distributor = expect_to_receive_and_return_real_now(
          Distributor, :build, logger, options
        )
        expect(real_distributor).to receive(:distribute)

        command.run([])
      end

      describe 'missing keys in the config' do
        context 'when required platform names are missing' do
          it 'raises an informative error' do
            fake_cred_repo = double(RemoteYamlCredentialProvider,
                                    credentials: {}
            )
            allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)
            allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

            expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
          end
        end

        context 'when required platform names are present' do
          context 'when aws credential keys are missing' do
            it 'raises an informative error' do
              fake_cred_repo = double(RemoteYamlCredentialProvider,
                                      credentials:
                                          {
                                              'aws' => {
                                              },
                                              'cloud_foundry' => {
                                                  'username' => 'your_CF_account',
                                                  'password' => 'your_CF_password',
                                                  'app_name' => 'your_app_name',
                                                  'api_endpoint' => 'your_api_endpoint',
                                                  'organization' => 'your_organization'
                                              }
                                          }
              )
              allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
            end
          end

          context 'when cloud foundry credential keys are missing' do
            it 'raises an informative error' do
              fake_cred_repo = double(RemoteYamlCredentialProvider,
                                      credentials:
                                          {
                                              'aws' => {
                                                  'access_key' => 'your_aws_access_key',
                                                  'secret_key' => 'your_aws_secret_key',
                                                  'green_builds_bucket' => 'your_aws_bucket'
                                              },
                                              'cloud_foundry' => {
                                              }
                                          }
              )
              allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)
              allow(configuration_fetcher).to receive(:fetch_config).and_return(config)

              expect { command.run([]) }.to raise_error PushFromLocal::CredentialKeyError
            end
          end
        end
      end

    end
  end
end
