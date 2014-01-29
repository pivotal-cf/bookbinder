require 'spec_helper'

describe GitClient do
  describe 'create_tag!' do
    let(:repo) { DocRepo.new({'github_repo'=>'foo/bar'}, nil, nil, nil) }
    let(:tagname) { 'sofia-1.0.1' }
    let(:full_name) { repo.full_name }
    let(:sha) { 'some-sha' }

    before { Octokit::Client.any_instance.stub(:commits) }

    it 'passes the right tag to OctoKit' do
      Octokit::Client.any_instance.should_receive(:create_ref).with(full_name, "tags/#{tagname}", sha)
      GitClient.new.create_tag!(full_name, tagname, sha)
    end
  end
end
