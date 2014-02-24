require 'spec_helper'

describe CredRepo do
  describe '#credentials' do
    let(:fixture_creds) do
      {'secure_site' => {'pass' => 'secret', 'handle' => 'agent'}}
    end
    let(:short_name) { 'creds-repo' }
    let(:repo) { CredRepo.new full_name: "org-name/#{short_name}" }

    before do
      stub_github_for repo.full_name
    end

    it 'returns a hash of the credentials in credentials.yml' do
      repo.credentials.should == fixture_creds
    end
  end
end
