require 'spec_helper'

module Bookbinder

  describe ConfigurationFetcher do
    let(:path_to_config_file) { './config.yml' }
    let(:config_validator)    { double('validator') }
    let(:logger)              { NilLogger.new }
    let(:loader)              { double('loader') }
    let(:config_fetcher)      { ConfigurationFetcher.new(logger, config_validator, loader) }

    it 'should have access to a ConfigurationValidator' do
      expect(config_fetcher.configuration_validator).to eq config_validator
    end

    before do
      config_fetcher.set_config_file_path(path_to_config_file)
    end

    describe 'setting the file path' do
      it 'should set the configuration file path' do
        expect(config_fetcher.config_file_path).to eq path_to_config_file
      end
    end

    describe 'fetching the config' do

      context 'when no configuration object exists' do
        let(:config_object) { nil }
        let(:section1) do
          {
              'repository' => {
                  'name' => 'foo/dogs-repo'
              },
              'directory' => 'concepts'
          }
        end
        let(:config_hash_in_file) do
          {
              'sections' => [section1],
              'public_host' => 'http://example.com',
          }
        end
        let(:expected_config_hash) do
          {
              'sections' => [section1],
              'public_host' => 'http://example.com',
              'pdf_index' => nil
          }
        end

        before do
          allow(config_validator).to receive(:valid?).and_return true
        end

        context 'and the configuration file does not exist' do
          it 'should raise an informative error' do
            allow(loader).to receive(:load).and_raise FileNotFoundError, "YAML"
            expect { config_fetcher.fetch_config }.to raise_error /The configuration file specified does not exist. Please create a config YAML file/
          end
        end

        context 'and the configuration file has valid syntax' do
          it 'should read a new configuration object from the configuration file' do
            allow(loader).to receive(:load).and_return(config_hash_in_file)
            expect(Configuration).to receive(:new).with(logger, expected_config_hash)
            config_fetcher.fetch_config
          end
        end

        context 'and the configuration file has invalid YAML syntax' do
          before do
            allow(loader).to receive(:load) { raise InvalidSyntaxError }
          end

          it 'raises an informative error' do
            expect { config_fetcher.fetch_config }.to raise_error /There is a syntax error in your config file/
          end
        end
      end

      context 'when a configuration object exists' do
        let(:loader) { double('loader') }
        let(:config_fetcher) { ConfigurationFetcher.new(logger, config_validator, loader) }
        let(:config_object) { double('config object') }

        it 'should not parse the user yml' do
          allow(config_validator).to receive(:valid?).and_return(true)
          expect(loader).to receive(:load).and_return({})

          config_fetcher.fetch_config

          expect(loader).not_to receive(:load)

          config_fetcher.fetch_config
        end
      end

    end
  end
end
