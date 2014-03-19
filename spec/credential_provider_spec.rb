require 'spec_helper'

describe CredentialProvider do
  describe '#credentials' do
    let(:fixture_creds) do
      {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}
    end
    let(:short_name) { 'creds-repo' }
    let(:full_name) { "org-name/#{short_name}" }
    let(:credentials_repository) { Repository.new(full_name: full_name) }
    let(:credentials) { CredentialProvider.new credentials_repository }

    before do
      stub_github_for full_name
    end

    it 'returns a hash of the credentials in credentials.yml' do
      expect(credentials.credentials).to eq(fixture_creds)
    end
  end
end
