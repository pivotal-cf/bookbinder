require_relative '../../../../lib/bookbinder/config/fetcher'

module Bookbinder
  module Config
    describe Fetcher do
      let(:path_to_config_file)   { './config.yml' }
      let(:path_to_config_dir)   { './config' }
      let(:config_validator)      { double('validator') }
      let(:loader)                { double('loader') }
      let(:credentials_provider)  { double('creds provider') }
      let(:config_fetcher)        { Fetcher.new(config_validator,
                                                loader,
                                                credentials_provider) }

      it 'can read config from a relative path even when I have changed working directory' do
        config_fetcher.set_config_file_path(path_to_config_file)
        config_fetcher.set_config_dir_path(path_to_config_dir)
        allow(Dir).to receive(:[]).and_return([])
        allow(config_validator).to receive(:exceptions).and_return []
        allow(loader).to receive(:load).with(File.expand_path(path_to_config_file)) { { foo: 'bar' } }
        Dir.chdir('/tmp') do |tmp|
          expect(config_fetcher.fetch_config).to eq(Configuration.parse(foo: 'bar'))
        end
      end

      it "fetches credentials when requested" do
        creds = { 'aws' => {'access_key' => 'foobar'},
                  'cloud_foundry' => {'cloud' => 'config'} }

        allow(loader).to receive(:load).with(File.expand_path('./some/path')) {
          { 'cred_repo' => 'git@myvcs.biz:org/repo' }
        }
        config_fetcher.set_config_file_path('./some/path')
        config_fetcher.set_config_dir_path(path_to_config_dir)
        allow(Dir).to receive(:[]).and_return([])

        allow(credentials_provider).
          to receive(:credentials).
          with('git@myvcs.biz:org/repo') { creds }
        allow(config_validator).to receive(:exceptions) { [] }
        expect(config_fetcher.fetch_credentials('acceptance')[:aws].access_key).to eq('foobar')
      end

      it "caches fetched credentials, even across environments (same raw config being fetched)" do
        allow(loader).to receive(:load) { { 'cred_repo' => 'org/repo' } }
        allow(config_validator).to receive(:exceptions) { [] }

        allow(credentials_provider).to receive(:credentials) { { 'some' => 'creds' } }
        prod_creds = config_fetcher.fetch_credentials('production')

        allow(credentials_provider).to receive(:credentials) { raise "shouldn't get here" }
        acceptance_creds = config_fetcher.fetch_credentials('acceptance')
        expect(acceptance_creds[:cloud_foundry]).not_to eq(prod_creds)
      end

      context 'when file path has been set, but no optional configs included' do
        before do
          config_fetcher.set_config_file_path(path_to_config_file)
          allow(config_validator).to receive(:exceptions) { [] }
          config_fetcher.set_config_dir_path(path_to_config_dir)
          allow(Dir).to receive(:[]).and_return([])
        end

        it 'reads a configuration object from the configuration file' do
          section1 = {
            'repository' => {
              'name' => 'foo/dogs-repo'
            },
            'directory' => 'concepts'
          }
          expected_config_hash = {
            'sections' => [section1],
            'public_host' => 'http://example.com',
          }
          config_hash_in_file = {
            'sections' => [section1],
            'public_host' => 'http://example.com',
          }
          allow(loader).to receive(:load).with(File.expand_path(path_to_config_file)) { config_hash_in_file }
          expect(config_fetcher.fetch_config).to eq(Configuration.parse(expected_config_hash))
        end

        it 'passes the configuration object to the validator' do
          input_hash = {'book_repo' => 'foo/baz', 'public_host' => 'foo.camels.io' }
          allow(loader).to receive(:load) { input_hash }
          expect(config_validator).to receive(:exceptions).with(Configuration.parse(input_hash))

          config_fetcher.fetch_config
        end

        it 'caches configuration loads' do
          expect(loader).to receive(:load) { {} }
          config_fetcher.fetch_config

          expect(loader).not_to receive(:load)
          config_fetcher.fetch_config
        end

        context 'when the configuration file does not exist' do
          it 'raises an informative error' do
            allow(loader).to receive(:load) { raise FileNotFoundError, 'YAML' }
            expect { config_fetcher.fetch_config }.to raise_error /The configuration file specified does not exist. Please create a config YAML file/
          end
        end

        context 'when the configuration file has invalid syntax' do
          it 'raises an informative error' do
            allow(loader).to receive(:load) { raise InvalidSyntaxError }
            expect { config_fetcher.fetch_config }.to raise_error /There is a syntax error in your config file/
          end
        end
      end

      context 'when the config is empty' do
        it 'raises' do
          allow(loader).to receive(:load).and_return nil
          expect { config_fetcher.fetch_config }.
              to raise_error /Your config.yml appears to be empty./
        end
      end

      context 'when the config is invalid' do
        it 'raises the error it receives' do
          error = RuntimeError.new
          allow(loader).to receive(:load) { {} }
          allow(config_validator).to receive(:exceptions).and_return([error])
          expect { config_fetcher.fetch_config }.to raise_error(error)
        end
      end

      context 'when optional config directory is present' do
        before do
          config_fetcher.set_config_file_path(path_to_config_file)
          config_fetcher.set_config_dir_path('./my-dir')
          allow(Dir).to receive(:[]).with(File.expand_path('./my-dir') + '/*.yml') { ['one.yml', 'two.yml'] }
        end
        it 'calls loader for config.yml and each file in config directory, and validates the merged hash' do
          allow(config_validator).to receive(:exceptions) { [] }

          expect(loader).to receive(:load).with(
              File.expand_path('config.yml')
          ).ordered { {config: 'yml', thing: {nested: 'item'}} }

          expect(loader).to receive(:load).with(
              File.expand_path('one.yml')
          ).ordered { {first: 'value'} }

          expect(loader).to receive(:load).with(
              File.expand_path('two.yml')
          ).ordered { {second: 'place'} }

          merged_hash = {config: 'yml', thing: {nested: 'item'}, first: 'value', second: 'place'}

          expect(config_validator).to receive(:exceptions).with(Configuration.parse(merged_hash))
          expect(config_fetcher.fetch_config).to eq(Configuration.parse(merged_hash))
        end

        context 'when optional configuration file has invalid syntax' do
          it 'raises an informative error' do
            allow(loader).to receive(:load).with(File.expand_path('config.yml')) { {} }
            allow(loader).to receive(:load).with(File.expand_path('one.yml')) { raise InvalidSyntaxError }
            expect { config_fetcher.fetch_config }.to raise_error /There is a syntax error in your config file/
          end
        end
      end
    end
  end
end
