require 'spec_helper'
require_relative '../lib/bookbinder/remote_yaml_credential_provider'

module Bookbinder
  describe RemoteYamlCredentialProvider do
    describe '#credentials' do
      subject(:credentials) do
        RemoteYamlCredentialProvider.new logger, credentials_repository, SpecGitAccessor
      end

      let(:logger) { double(Logger).as_null_object }
      let(:fixture_creds) do
        {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}
      end
      let(:full_name) { 'org-name/creds-repo' }
      let(:credentials_repository) do
        GitHubRepository.new(logger: logger, full_name: 'org-name/creds-repo')
      end

      it 'returns a hash of the credentials in credentials.yml' do
        expect(credentials.credentials).to eq(fixture_creds)
      end

      it 'logs a processing message' do
        expect(logger).to receive(:log).with("Processing #{full_name.cyan}")
        credentials.credentials
      end
    end
  end
end
