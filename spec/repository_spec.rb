require 'spec_helper'

describe Repository do
  include_context 'tmp_dirs'

  describe '#tag_with' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(github, full_name)
          @github = github
          @full_name = full_name
        end
      end
    end

    it 'calls #create_tag! on the github instance variable' do
      fake_github = double

      expect(fake_github).to receive(:create_tag!).with('org/repo', 'the_tag_name', 'master')

      klass.new(fake_github, 'org/repo').tag_with('the_tag_name')
    end
  end

  describe '#target_ref' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(target_ref)
          @ref = target_ref
        end
      end
    end

    it 'uses @ref if set' do
      expect(klass.new('foo').target_ref).to eq('foo')
    end

    it 'defaults to "master"' do
      expect(klass.new(nil).target_ref).to eq('master')
    end
  end

  describe '#short_name' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(full_name)
          @full_name = full_name
        end
      end
    end

    it 'returns the repo name when org and repo name are provided' do
      expect(klass.new('some-org/some-name').short_name).to eq('some-name')
    end
  end

  describe '#head_sha' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(github, full_name, head_sha)
          @github = github
          @full_name = full_name
          @head_sha = head_sha
        end
      end
    end

    it 'returns @head_sha if set' do
      expect(klass.new(nil, nil, 'abcd').head_sha).to eq('abcd')
    end

    it "returns the first (most recent) commit's sha if @head_sha is unset" do
      fake_commit = double(sha: 'dcba')
      fake_github = double
      expect(fake_github).to receive(:commits).with('org/repo').and_return([fake_commit, nil])
      expect(klass.new(fake_github, 'org/repo', nil).head_sha).to eq('dcba')
    end
  end

  describe '#directory' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(directory, full_name)
          @directory = directory
          @full_name = full_name
        end
      end
    end

    it 'returns @directory if set' do
      expect(klass.new('the_directory', nil).directory).to eq('the_directory')
    end

    it 'returns #short_name if @directory is unset' do
      expect(klass.new(nil, 'org/repo').directory).to eq('repo')
    end
  end

  describe 'copy_from_remote' do
    let(:klass) do
      Class.new(Repository) do
        def initialize(full_name, sha, github)
          @full_name = full_name
          @ref = sha
          @github = github
        end
      end
    end
    let(:repo_name) { 'org/my-docs-repo' }
    let(:some_sha) { 'some-sha' }
    let(:repo) { klass.new(repo_name, some_sha, github) }
    let(:destination_dir) { tmp_subdir('destination') }
    let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }
    let(:github) do
      git = double
      allow(git).to receive(:archive_link).with(repo_name, ref: some_sha).
                    and_return("https://github.com/#{repo_name}/archive/#{some_sha}.tar.gz")
      git
    end

    def copy_to
      repo.copy_from_remote(destination_dir)
    end

    before { stub_github_for repo_name, some_sha }

    it 'retrieves the repo from github' do
      copy_to
      expect(File.exist? File.join(destination_dir, 'my-docs-repo', 'index.html.md')).to be_true
    end

    it 'returns true' do
      expect(copy_to).to be_true
    end

    context 'when given an invalid request URL' do
      before do
        zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_sha}.tar.gz"
        stub_request(:get, zipped_repo_url).to_return(:body => '', :status => 406)
      end

      it 'raises an error' do
        expect { copy_to }.to raise_exception(/Unable to download/)
      end
    end
  end
end
