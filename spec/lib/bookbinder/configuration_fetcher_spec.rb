require_relative '../../../lib/bookbinder/configuration_fetcher'

module Bookbinder
  describe ConfigurationFetcher do
    let(:path_to_config_file) { './config.yml' }
    let(:config_validator)    { double('validator') }
    let(:logger)              { double('logger') }
    let(:loader)              { double('loader') }
    let(:config_fetcher)      { ConfigurationFetcher.new(logger, config_validator, loader) }

    before do
      config_fetcher.set_config_file_path(path_to_config_file)
    end

    describe 'fetching the config' do
      before do
        allow(config_validator).to receive(:valid?).and_return true
      end

      context 'when the configuration file has valid syntax' do
        it 'should read a new configuration object from the configuration file' do
          section1 = {
            'repository' => {
              'name' => 'foo/dogs-repo'
            },
            'directory' => 'concepts'
          }
          expected_config_hash = {
            'sections' => [section1],
            'public_host' => 'http://example.com',
            'pdf_index' => nil
          }
          config_hash_in_file = {
            'sections' => [section1],
            'public_host' => 'http://example.com',
          }
          allow(loader).to receive(:load).with(path_to_config_file).
            and_return(config_hash_in_file)
          expect(Configuration).to receive(:new).with(logger, expected_config_hash)
          config_fetcher.fetch_config
        end
      end

      it 'caches configuration loads' do
        allow(config_validator).to receive(:valid?).and_return(true)

        expect(loader).to receive(:load).and_return({})
        config_fetcher.fetch_config

        expect(loader).not_to receive(:load)
        config_fetcher.fetch_config
      end

      context 'when the configuration file does not exist' do
        it 'should raise an informative error' do
          allow(loader).to receive(:load).with(path_to_config_file).
            and_raise FileNotFoundError, "YAML"
          expect { config_fetcher.fetch_config }.to raise_error /The configuration file specified does not exist. Please create a config YAML file/
        end
      end

      context 'when the configuration file has invalid YAML syntax' do
        before do
          allow(loader).to receive(:load) { raise InvalidSyntaxError }
        end

        it 'raises an informative error' do
          expect { config_fetcher.fetch_config }.to raise_error /There is a syntax error in your config file/
        end
      end
    end
  end
end
