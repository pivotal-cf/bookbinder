require 'spec_helper'

module Bookbinder
  describe Repository do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:github_token) { 'blahblah' }
    let(:git_client) { GitClient.new(logger, access_token: github_token) }

    before do
      allow(GitClient).to receive(:new).and_call_original
      allow(GitClient).to receive(:new).with(logger, access_token: github_token).and_return(git_client)
      allow(ProgressBar).to receive(:create).and_return(double(increment: nil))
    end

    it 'requires a full_name' do
      expect {
        Repository.new(logger: logger, github_token: github_token, full_name: '')
      }.not_to raise_error

      expect {
        Repository.new(logger: logger, github_token: github_token)
      }.to raise_error(/full_name/)
    end

    describe '#tag_with' do
      let(:head_sha) { 'ha7f'*10 }

      it 'calls #create_tag! on the github instance variable' do
        expect(git_client).to receive(:head_sha).with('org/repo').and_return head_sha
        expect(git_client).to receive(:create_tag!).with('org/repo', 'the_tag_name', head_sha)

        Repository.new(logger: logger, github_token: github_token, full_name: 'org/repo').tag_with('the_tag_name')
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
        fake_github = double(:github)

        expect(GitClient).to receive(:new).
                                 with(logger, access_token: github_token).
                                 and_return(fake_github)

        expect(fake_github).to receive(:head_sha).with('org/repo').and_return('dcba')

        repository = Repository.new(logger: logger, full_name: 'org/repo', github_token: github_token)
        expect(repository.head_sha).to eq('dcba')
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
      let(:repo) { Repository.new(logger: logger, full_name: repo_name, target_ref: some_sha, github_token: 'foo') }
      let(:destination_dir) { tmp_subdir('destination') }
      let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }
      let(:git_client) { GitClient.new(logger) }

      before do
        stub_github_for git_client, repo_name, some_sha
        allow(GitClient).to receive(:new).and_return git_client
      end

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

      context 'when the docs directory already exists in the destination' do
        before do
          directory = File.join(destination_dir, 'my-docs-repo')
          FileUtils.mkdir directory
        end

        it 'moves the contents of the source directory to the top level of the destination' do
          repo.copy_from_remote(destination_dir)
          expect(File.exist? File.join(destination_dir, 'my-docs-repo', 'index.html.md')).to be_true
        end
      end
    end

    describe '#copy_from_local' do
      let(:full_name) { 'org/my-docs-repo' }
      let(:target_ref) { 'some-sha' }
      let(:local_repo_dir) { tmp_subdir 'local_repo_dir' }
      let(:repo) { Repository.new(logger: logger, full_name: full_name, target_ref: target_ref, local_repo_dir: local_repo_dir) }

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

    describe '#has_tag?' do
      let(:repo) { Repository.new(full_name: 'my-docs-org/my-docs-repo',
                                  target_ref: 'some_sha',
                                  directory: 'pretty_url_path',
                                  local_repo_dir: '') }
      let(:my_tag) { '#hashtag' }

      before do
        allow(GitClient).to receive(:new).and_return(git_client)
        allow(git_client).to receive(:tags).and_return(tags)
      end

      context 'when a tag has been applied' do
        let(:tags) do
          [OpenStruct.new(name: my_tag)]
        end

        it 'is true when checking that tag' do
          expect(repo).to have_tag(my_tag)
        end
        it 'is false when checking a different tag' do
          expect(repo).to_not have_tag('nobody_uses_me')
        end
      end

      context 'when no tag has been applied' do
        let(:tags) { [] }

        it 'is false' do
          expect(repo).to_not have_tag(my_tag)
        end
      end
    end

    describe '#tag_with' do
      let(:repo_sha) { 'some-sha' }
      let(:repo) { Repository.new(logger: logger,
                                  github_token: github_token,
                                  full_name: 'my-docs-org/my-docs-repo',
                                  target_ref: repo_sha,
                                  directory: 'pretty_url_path',
                                  local_repo_dir: '') }
      let(:my_tag) { '#hashtag' }

      before do
        allow(git_client).to receive(:validate_authorization)
        allow(git_client).to receive(:commits).with(repo.full_name)
                             .and_return([OpenStruct.new(sha: repo_sha)])
      end

      it 'should apply a tag' do
        expect(git_client).to receive(:create_tag!)
                              .with(repo.full_name, my_tag, repo_sha)

        repo.tag_with(my_tag)
      end
    end

    describe '#update_local_copy' do
      let(:local_repo_dir) { tmpdir }
      let(:full_name) { 'org/repo-name' }
      let(:repo_dir) { File.join(local_repo_dir, 'repo-name') }
      let(:repository) { Repository.new(logger: logger, github_token: github_token, full_name: full_name, local_repo_dir: local_repo_dir) }

      context 'when the repo dirs are there' do
        before do
          Dir.mkdir repo_dir
        end

        it 'issues a git pull in each repo' do
          expect(Kernel).to receive(:system).with("cd #{repo_dir} && git pull")
          repository.update_local_copy
        end
      end

      context 'when a repo is not there' do
        it 'does not attempt a git pull' do
          expect(Kernel).to_not receive(:system)
          repository.update_local_copy
        end
      end
    end

    describe '#download_archive' do
      let(:full_name) { 'org/my-docs-repo' }
      let(:existing_ref) { 'some-sha' }
      let(:target_ref) { existing_ref }
      let(:archive_head_url) { "https://api.github.com/repos/#{full_name}/tarball/#{target_ref}" }
      let(:tar_url) { "https://codeload.github.com/#{full_name}/legacy.tar.gz/#{target_ref}" }

      let(:repo) { Repository.new(logger: logger, github_token: github_token, full_name: full_name, target_ref: target_ref) }

      before do
        stub_refs_for_repo(full_name, [existing_ref])
        stub_request(:head, archive_head_url).to_return(status: 302, body: "", headers: {'Location' => tar_url})
      end

      context 'when the repo and ref is visible' do
        let(:github_archive) { "my_archive".bytes }

        before do
          stub_request(:get, tar_url).to_return(
              body: github_archive, headers: {'Content-Type' => 'application/x-gzip'}
          )
        end

        it 'gives us the archive from github for the repository' do
          expect(repo.download_archive).to eq(github_archive)
        end
      end

      context 'when given a non-existent tag' do
        before do
          stub_request(:get, "https://codeload.github.com/org/my-docs-repo/legacy.tar.gz/some-sha").
              to_return(:status => 404)
        end

        it 'gives an informative error message' do
          expect { repo.download_archive }.to raise_error(RuntimeError, /#{target_ref}/)
        end
      end
    end

    describe '#shas_by_file' do
      let(:target_ref) { 'arbitrary-reference' }
      let(:full_name) { 'org/my-docs-repo' }
      let(:repo) do
        Repository.new(logger: logger, github_token: github_token, full_name: full_name, target_ref: target_ref)
      end
      let(:tree) { {tree: [{path: 'fake-path/file.mp3', sha: 'fake-sha'}]} }
      let(:git_client) { double(:octokit) }

      before do
        allow(GitClient).to receive(:new).and_return git_client
      end

      it 'returns a hash' do
        allow(git_client).to receive(:tree).and_return tree
        expect(repo.shas_by_file).to eq({'fake-path/file.mp3' => 'fake-sha'})
      end

      it 'recursively searches the entire tree at teh target ref' do
        expect(git_client).to receive(:tree).with(full_name, target_ref, recursive: true).and_return tree
        repo.shas_by_file
      end
    end

    describe '#dates_by_sha' do
      let(:repo) do
        Repository.new(logger: logger, github_token: github_token, full_name: full_name, target_ref: target_ref)
      end

      let(:full_name) { 'org/my-docs-repo' }
      let(:target_ref) { 'arbitrary-reference' }
      let(:git_client) { double(:octokit) }
      let(:shas_by_file) { {
          'file-path1' => 'cached-sha-1',
          'file-path2' => 'cached-sha-2'
      }
      }

      before do
        allow(GitClient).to receive(:new).and_return git_client
      end

      context 'when a sha is cached' do
        let(:modified_date) { rand 1000 }
        let(:cached_shas) { {'cached-sha-1' => modified_date} }


        it 'does not return it in the result' do
          allow(git_client).to receive(:last_modified_date_of).with("org/my-docs-repo", "arbitrary-reference", "file-path2").and_return(modified_date)
          expect(repo.dates_by_sha(shas_by_file, except: cached_shas)).to eq('cached-sha-2' => modified_date)
        end
      end

      context 'when a sha is not cached' do
        let(:earlier) { 0 }
        let(:later) { 1978 }
        let(:cached_shas) { {} }

        it 'returns all results' do
          expect(git_client).to receive(:last_modified_date_of).with("org/my-docs-repo", "arbitrary-reference", "file-path1").and_return(earlier)
          expect(git_client).to receive(:last_modified_date_of).with("org/my-docs-repo", "arbitrary-reference", "file-path2").and_return(later)

          expect(repo.dates_by_sha(shas_by_file, except: cached_shas)).to eq({'cached-sha-1' => earlier,'cached-sha-2' => later})
        end
      end
    end
  end
end