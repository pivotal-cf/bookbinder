require 'spec_helper'

describe CredentialProvider do
  describe '#credentials' do
    let(:logger) { NilLogger.new }
    let(:fixture_creds) do
      {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}
    end
    let(:short_name) { 'creds-repo' }
    let(:full_name) { "org-name/#{short_name}" }
    let(:credentials_repository) { Repository.new(logger: logger, full_name: full_name) }
    let(:credentials) { CredentialProvider.new logger, credentials_repository }
    let(:git_client) { GitClient.new(logger) }

    before do
      stub_github_for git_client, full_name
      allow(GitClient).to receive(:new).and_return(git_client)
    end

    it 'returns a hash of the credentials in credentials.yml' do
      expect(credentials.credentials).to eq(fixture_creds)
    end
  end
end
