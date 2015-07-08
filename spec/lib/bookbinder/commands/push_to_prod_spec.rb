require_relative '../../../../lib/bookbinder/commands/push_to_prod'
require_relative '../../../../lib/bookbinder/config/aws_credentials'
require_relative '../../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Commands
    describe PushToProd do
      around do |example|
        Fog.mock!
        Fog::Mock.reset
        example.run
        Fog.unmock!
      end

      before do
        fog_connection = Fog::Storage.new(provider: 'AWS',
                                          aws_access_key_id: 'access_key',
                                          aws_secret_access_key: 'secret_key',
                                          region: 'us-east-1')
        fog_connection.directories.create key: 'green_bucket_name'
      end

      let(:configuration_fetcher) {
        double(
          'configuration_fetcher',
          fetch_credentials: {
            aws: Config::AwsCredentials.new({'access_key' => 'access_key',
                                             'secret_key' => 'secret_key',
                                             'green_builds_bucket' => 'green_bucket_name'}),
            cloud_foundry: Config::CfCredentials.new({}, 'production')
          }
        )
      }

      it "tries to download an existing tarball" do
        allow(configuration_fetcher).to receive(:fetch_config) {
          Config::Configuration.new(book_repo: 'my_book', cred_repo: 'my_cred_repo', public_host: 'public_host', sections: [])
        }
        push = PushToProd.new({warn: StringIO.new},
                              logger = nil,
                              configuration_fetcher,
                              'integrationy/test')
        expect { push.run(['123']) }.to raise_error(Deploy::Archive::FileDoesNotExist)
      end

      context 'when missing credential repo' do
        it 'raises missing credential key error' do
          allow(configuration_fetcher).to receive(:fetch_config) {
            Config::Configuration.new(book_repo: 'my_book', public_host: 'public_host', sections: [])
          }
          expect { PushToProd.new({warn: StringIO.new}, logger = nil, configuration_fetcher, 'missing/key/app/dir').
                   run(['321']) }.to raise_error PushToProd::MissingRequiredKeyError, /Your config.yml is missing required key\(s\). The require keys for this commands are /
        end
      end
    end
  end
end
