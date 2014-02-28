require 'spec_helper'

describe Cli::CommandRequiringCredentials do
  include_context 'tmp_dirs'

  class FakeCommandRequiringCredentials
    include Cli::CommandRequiringCredentials
  end

  let(:command) { FakeCommandRequiringCredentials.new }
  let(:config_path) { './config.yml' }

  describe '#config' do
    before do
      stub_github_for('fantastic/creds-repo')
    end

    around_with_fixture_repo do |example|
      example.run
    end

    it 'exposes config.yml' do
      expect(command.config['book_repo']).to eq('fantastic/fixture-book-title')
    end

    it 'merges in the cred_repo credentials' do
      expect(command.config['secure_site']['pass']).to eq('secret')
      expect(command.config['secure_site']['handle']).to eq('agent')
    end

    context 'if config.yml is empty' do
      it 'raises' do
        File.open(config_path, 'w') { |f| f.write('') }

        expect {
          command.config
        }.to raise_error('config.yml is empty')
      end
    end

    context 'if cred_repo is not present' do
      before do
        config = YAML.load(File.read(config_path))
        config.delete('cred_repo')
        File.open(config_path, 'w') { |f| f.write(YAML.dump(config)) }
      end

      it 'raises' do
        expect {
          command.config
        }.to raise_error(/A credentials repository must be specified/)
      end
    end
  end
end
