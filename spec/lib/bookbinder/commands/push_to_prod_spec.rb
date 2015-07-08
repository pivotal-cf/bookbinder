require_relative '../../../../lib/bookbinder/commands/push_to_prod'
require_relative '../../../../lib/bookbinder/config/aws_credentials'
require_relative '../../../../lib/bookbinder/config/cf_credentials'
require_relative '../../../../lib/bookbinder/config/configuration'

module Bookbinder
  module Commands
    describe PushToProd do
      let(:configuration_fetcher) {
        double(
          'configuration_fetcher',
          fetch_credentials: {
            aws: Config::AwsCredentials.new({}),
            cloud_foundry: Config::CfCredentials.new({}, 'production')
          }
        )
      }

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
