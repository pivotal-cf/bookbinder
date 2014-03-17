require 'spec_helper'

describe Repository do
  include_context 'tmp_dirs'

  it 'requires a full_name' do
    expect {
      Repository.new(full_name: '')
    }.not_to raise_error

    expect {
      Repository.new
    }.to raise_error(/full_name/)
  end

  describe '#tag_with' do
    let(:github_token) { 'blahblah' }

    it 'calls #create_tag! on the github instance variable' do
      fake_github = double
      expect(GitClient).to receive(:get_instance).
                             with(access_token: github_token).
                             and_return(fake_github)
      expect(fake_github).to receive(:create_tag!).
                               with('org/repo', 'the_tag_name', 'master')

      Repository.new(github_token: github_token, full_name: 'org/repo').tag_with('the_tag_name')
    end
  end

  describe '#target_ref' do
    it 'uses @ref if set' do
      expect(Repository.new(full_name: '', target_ref: 'foo').target_ref).to eq('foo')
    end

    it 'defaults to "master"' do
      expect(Repository.new(full_name: 'foo').target_ref).to eq('master')
    end
  end

  describe '#short_name' do
    it 'returns the repo name when org and repo name are provided' do
      expect(Repository.new(full_name: 'some-org/some-name').short_name).to eq('some-name')
    end
  end

  describe '#head_sha' do
    let(:github_token) { 'my_token' }

    it "returns the first (most recent) commit's sha if @head_sha is unset" do
      fake_github = double
      fake_commit = double(sha: 'dcba')
      expect(GitClient).to receive(:get_instance).
                             with(access_token: github_token).
                             and_return(fake_github)

      expect(fake_github).to receive(:commits).with('org/repo').and_return([fake_commit, '1234', '4567'])

      expect(Repository.new(full_name: 'org/repo', github_token: github_token).head_sha).to eq('dcba')
    end
  end

  describe '#directory' do
    it 'returns @directory if set' do
      expect(Repository.new(full_name: '', directory: 'the_directory').directory).to eq('the_directory')
    end

    it 'returns #short_name if @directory is unset' do
      expect(Repository.new(full_name: 'org/repo').directory).to eq('repo')
    end
  end

  describe 'copy_from_remote' do
    let(:repo_name) { 'org/my-docs-repo' }
    let(:some_sha) { 'some-sha' }
    let(:repo) { Repository.new(full_name: repo_name, target_ref: some_sha, github_token: 'foo') }
    let(:destination_dir) { tmp_subdir('destination') }
    let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }

    before { stub_github_for repo_name, some_sha }

    it 'retrieves the repo from github' do
      repo.copy_from_remote(destination_dir)
      expect(File.exist? File.join(destination_dir, 'my-docs-repo', 'index.html.md')).to be_true
    end

    it 'returns true' do
      expect(repo.copy_from_remote(destination_dir)).to be_true
    end

    it 'sets copied? to true' do
      expect { repo.copy_from_remote(destination_dir) }.to change { repo.copied? }.to(true)
    end

    context 'when given an invalid request URL' do
      before do
        zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_sha}.tar.gz"
        stub_request(:get, zipped_repo_url).to_return(:body => '', :status => 406)
      end

      it 'raises an error' do
        expect {
          repo.copy_from_remote(destination_dir)
        }.to raise_exception(/Unable to download/)
      end

      it 'does not change copied?' do
        expect { repo.copy_from_remote(destination_dir) rescue nil }.not_to change { repo.copied? }
      end
    end
  end

  describe '#copy_from_local' do
    let(:full_name) { 'org/my-docs-repo' }
    let(:target_ref) { 'some-sha' }
    let(:local_repo_dir) { tmp_subdir 'local_repo_dir' }
    let(:repo) { Repository.new(full_name: full_name, target_ref: target_ref, local_repo_dir: local_repo_dir) }

    let(:destination_dir) { tmp_subdir('destination') }
    let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }

    let(:copy_to) { repo.copy_from_local destination_dir }

    context 'and the local repo is there' do
      before do
        Dir.mkdir repo_dir
        FileUtils.touch File.join(repo_dir, 'my_aunties_goat.txt')
      end

      it 'returns true' do
        expect(copy_to).to be_true
      end

      it 'copies the repo' do
        copy_to
        expect(File.exist? File.join(destination_dir, 'my-docs-repo', 'my_aunties_goat.txt')).to be_true
      end

      it 'sets copied? to true' do
        expect { copy_to }.to change { repo.copied? }.to(true)
      end
    end

    context 'and the local repo is not there' do
      before do
        expect(File.exist? repo_dir).to be_false
      end
      it 'returns false' do
        expect(copy_to).to be_false
      end

      it 'does not change copied?' do
        expect { copy_to }.not_to change { repo.copied? }
      end
    end
  end
end
