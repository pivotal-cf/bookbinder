require 'spec_helper'

module Bookbinder
  describe CredentialProvider do
    describe '#credentials' do


      subject(:credentials) do
        CredentialProvider.new logger, credentials_repository, SpecGitAccessor
      end

      let(:logger) { double(Logger).as_null_object }
      let(:fixture_creds) do
        {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}
      end
      let(:full_name) { 'org-name/creds-repo' }
      let(:credentials_repository) do
        Repository.new(logger: logger, full_name: 'org-name/creds-repo')
      end
      let(:github) {"https://#{ENV['GITHUB_API_TOKEN']}:x-oauth-basic@github.com"}

      before do
        allow_any_instance_of(Repository).to receive(:get_repo_url) { |o, name | "#{github}/#{name}"}
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