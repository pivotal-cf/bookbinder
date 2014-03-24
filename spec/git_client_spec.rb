require 'spec_helper'

describe GitClient do
  let(:client) { GitClient.get_instance }
  let(:repo_name) { 'foo/bar' }

  describe 'create_tag!' do
    let(:tagname) { 'sofia-1.0.1' }
    let(:sha) { 'some-sha' }
    let(:iso_time) { '2014-03-18T17:26:38-07:00' }
    let(:tag_sha) { 'tag-sha' }
    let(:tag_result) { double(sha: tag_sha) }

    before do
      allow(Time).to receive(:now).and_return(double(:time, iso8601: iso_time))
    end

    it 'creates a tag for the incoming ref' do
      expect(client).to receive(:create_tag).with(repo_name, "tags/#{tagname}", 'Tagged by Bookbinder', sha, 'commit', 'Bookbinder', 'bookbinder@cloudfoundry.org', iso_time).and_return(tag_result).ordered
      allow(client).to receive(:create_ref).ordered

      client.create_tag!(repo_name, tagname, sha)
    end

    it 'creates a ref to the newly created tag' do
      allow(client).to receive(:create_tag).and_return(tag_result).ordered
      expect(client).to receive(:create_ref).with(repo_name, "tags/#{tagname}", tag_sha).ordered

      client.create_tag!(repo_name, tagname, sha)
    end
  end

  describe '#head_sha' do
    let(:latest_commit) { double(:commit, sha: 'gummy-bears') }

    before do
      stub_request(:get, 'https://api.github.com/repos/foo/bar/commits').
          to_return(:status => 200, :body => [latest_commit], :headers => {})
    end

    it 'returns the sha of the latest commit' do
      expect(client.head_sha(repo_name)).to eq latest_commit.sha
    end
  end
end
