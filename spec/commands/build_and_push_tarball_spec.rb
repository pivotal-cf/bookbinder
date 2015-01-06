require_relative '../../lib/bookbinder/commands/build_and_push_tarball'
require_relative '../helpers/tmp_dirs'
require_relative '../helpers/nil_logger'
require_relative '../../lib/bookbinder/configuration'

module Bookbinder
  describe Commands::BuildAndPushTarball do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:configuration_fetcher) { double('configuration_fetcher') }
    let(:config) { Configuration.new(logger, config_hash) }
    let(:build_and_push_tarball_command) { Commands::BuildAndPushTarball.new(logger, configuration_fetcher) }
    let(:build_number) { '17' }
    let(:book_repo) { 'org/fixture-book-title' }

    let(:aws_hash) do
      {
          'aws' => {
              'green_builds_bucket' => bucket,
              'access_key' => access_key,
              'secret_key' => secret_key,
          }
      }
    end
    let(:config_hash) do
      {
          'book_repo' => book_repo,
          'cred_repo' => 'some/repo'
      }
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('BUILD_NUMBER').and_return(build_number)
      fake_creds = double
      allow(fake_creds).to receive(:credentials).and_return(aws_hash)
      allow(RemoteYamlCredentialProvider).to receive(:new).and_return(fake_creds)
      allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
    end

    let(:access_key) { 'access-key' }
    let(:secret_key) { 'secret-key' }
    let(:bucket) { 'bucket-name-in-fixture-config' }

    it 'should call GreenBuildRepository#create with correct parameters' do
      expect(Archive).to receive(:new).with(logger: logger, key: access_key, secret: secret_key).and_call_original
      expect_any_instance_of(Archive).to receive(:create_and_upload_tarball) do |archive, args|
        expect(args).to have_key(:build_number)
        expect(args).to have_key(:bucket)
        expect(args).to have_key(:namespace)

        expect(args.fetch(:bucket)).to eq bucket
        expect(args.fetch(:build_number)).to eq build_number
        expect(args.fetch(:namespace)).to eq 'fixture-book-title'
      end

      build_and_push_tarball_command.run []
    end
  end
end
