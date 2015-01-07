require_relative '../../lib/bookbinder/commands/push_local_to_staging'
require_relative '../../lib/bookbinder/remote_yaml_credential_provider'
require_relative '../../lib/bookbinder/configuration'
require_relative '../helpers/nil_logger'
require_relative '../helpers/middleman'

module Bookbinder
  describe Commands::PushLocalToStaging do
    include SpecHelperMethods

    let(:book_repo) { 'my-user/fixture-book-title' }
    let(:config_hash) { {'book_repo' => book_repo, 'cred_repo' => 'whatever'} }

    let(:fake_distributor) { double(Distributor, distribute: nil) }

    let(:options) do
      {
          app_dir: './final_app',
          build_number: nil,

          aws_credentials: config.aws_credentials,
          cf_credentials: config.cf_staging_credentials,

          book_repo: book_repo,
          production: false
      }
    end

    let(:logger) { NilLogger.new }
    let(:configuration_fetcher) { double('configuration_fetcher') }
    let(:config) { Configuration.new(logger, config_hash) }
    let(:command) { described_class.new(logger, configuration_fetcher) }

    before do
      fake_cred_repo = double(RemoteYamlCredentialProvider, credentials: {'aws' => {}, 'cloud_foundry' => {}})
      allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_cred_repo)

      allow(Distributor).to receive(:build).and_return(fake_distributor)
      allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
    end

    it 'returns 0' do
      expect(command.run([])).to eq(0)
    end

    it 'builds a distributor with the right options and asks it to distribute' do
      real_distributor = expect_to_receive_and_return_real_now(Distributor, :build, logger, options)
      expect(real_distributor).to receive(:distribute)

      command.run([])
    end
  end
end
