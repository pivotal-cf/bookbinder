require 'spec_helper'

describe GitClient do
  describe 'create_tag!' do
    let(:tagname) { 'sofia-1.0.1' }
    let(:repo_name) { 'foo/bar' }
    let(:sha) { 'some-sha' }
    let(:client) { GitClient.get_instance }
    let(:iso_time) { '2014-03-18T17:26:38-07:00' }

    before do
      allow(Time).to receive(:now).and_return(double(:time, iso8601: iso_time))
    end

    it 'passes the right refname to OctoKit' do
      allow(client).to receive(:create_tag)

      expect(client).to receive(:create_ref).with(repo_name, "tags/#{tagname}", sha)
      client.create_tag!(repo_name, tagname, sha)
    end

    it 'passes the right tag to OctoKit' do
      allow(client).to receive(:create_ref)

      expect(client).to receive(:create_tag).with(repo_name, "tags/#{tagname}", 'Tagged by Bookbinder', sha, 'commit', 'Bookbinder', 'bookbinder@cloudfoundry.org', iso_time)
      client.create_tag!(repo_name, tagname, sha)
    end
  end
end
