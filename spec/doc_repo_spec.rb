require 'spec_helper'

describe DocRepo do

  include ShellOut
  include_context 'tmp_dirs'

  describe '.from_remote' do
    context 'and github returns a 200 status code' do
      before do
        stub_request(:get, download_url).
            to_return(
            :status => 200,
            :body => zipped_markdown_repo,
            :headers => {'Content-Type' => 'application/x-gzip'}
        )
      end

      let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'dogs-repo', sha }
      let(:destination_dir) { tmp_subdir('output') }
      let(:repo_name) { 'great_org/dogs-repo' }
      let(:download_url) { "https://github.com/great_org/dogs-repo/archive/#{sha}.tar.gz" }

      context 'when no SHA is provided' do
        let(:sha) { 'master' }
        let(:repo_hash) { {'github_repo' => repo_name} }

        it 'uses "master" to make requests for the archive link' do
          GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: sha).and_return(download_url)
          DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir)
        end

        it 'copies the repo from github' do
          GitClient.any_instance.stub(:archive_link).and_return download_url
          DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir)
          expect(File.exist? File.join(destination_dir, 'dogs-repo', 'index.html.md.erb')).to be_true
        end

        context 'and a target_tag is provided' do
          let(:target_tag) { 'oh-dot-three-dot-oh' }

          it 'uses the tag to make requests for the archive link' do
            GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: target_tag).and_return(download_url)
            DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir, target_tag: target_tag)
          end
        end
      end

      context 'when a SHA is provided' do
        let(:sha) { 'this-is-the-commit-i-want' }
        let(:repo_hash) { {'github_repo' => repo_name, 'sha' => sha} }

        it 'uses the provided SHA to make requests for the archive link' do
          GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: sha).and_return download_url
          DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir)
        end

        it 'copies the repo from github' do
          GitClient.any_instance.stub(:archive_link).and_return download_url
          DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir)
          expect(File.exist? File.join(destination_dir, 'dogs-repo', 'index.html.md.erb')).to be_true
        end

        context 'and a target_tag is provided' do
          let(:target_tag) { 'oh-dot-three-dot-oh' }
          it 'uses the tag to make requests for the archive link' do
            GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: target_tag).and_return(download_url)
            DocRepo.from_remote(repo_hash: repo_hash, destination_dir: destination_dir, target_tag: target_tag)
          end
        end
      end
    end
  end

  describe '.from_local' do
    let(:repo_name) { 'aunties-repo' }
    let(:local_repo_dir) { tmp_subdir 'local_repo_dir' }
    let(:destination_dir) { tmp_subdir('output') }
    let(:repo_dir) { File.join(local_repo_dir, repo_name) }

    before do
      Dir.mkdir repo_dir
      FileUtils.touch File.join(repo_dir, 'my_aunties_goat.txt')
    end

    it 'copies the repo from nearby' do
      DocRepo.from_local(repo_hash: {'github_repo' => 'crazy_family_of_mine/' + repo_name},
                         local_dir: local_repo_dir,
                         destination_dir: destination_dir)
      expect(File.exist? File.join(destination_dir, repo_name, 'my_aunties_goat.txt')).to be_true
    end
  end

  describe '#download_and_unzip' do
    let(:destination_dir) { tmp_subdir 'middleman_source_dir' }
    let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
    let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo', 'sha' => 'some-sha'} }
    let(:repo) { DocRepo.new(repo_hash, nil, local_repo_dir, nil) }

    context 'when told to look for repos on github' do
      let(:local_repo_dir) { nil }
      let(:tarball_url) { 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz' }

      before do
        GitClient.any_instance.stub(:commits).and_return [OpenStruct.new(sha: 'some-sha')]
        GitClient.any_instance.stub(:validate_authorization)
        GitClient.any_instance.stub(:archive_link).and_return tarball_url
      end

      it 'downloads and unzips the repo' do
        stub_request(:get, tarball_url).to_return(
            :body => zipped_markdown_repo, :headers => {'Content-Type' => 'application/x-gzip'}
        )
        repo.copy_from_remote destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end

    context 'when told to look for repos locally' do
      let(:local_repo_dir) { MarkdownRepoFixture.markdown_repos_dir }

      it 'finds them in the supplied directory' do
        repo.copy_from_local destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end

      context 'when the repo is not present in the supplied directory' do
        let(:repo_hash) { {'github_repo' => 'my-docs-org/my-non-existent-docs-repo'} }
        it 'gracefully skips repos that are not present in the supplied directory' do
          repo.copy_from_local destination_dir
          new_entries = Dir.entries(destination_dir) - ['..', '.']
          expect(new_entries.size).to eq(0)
        end
      end
    end

    context 'when a custom directory is specified for the repo' do
      let(:local_repo_dir) { MarkdownRepoFixture.markdown_repos_dir }
      let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo',
                         'sha' => 'some-sha', 'directory' => 'pretty_url_path'} }

      it 'puts the repo into that directory' do
        repo.copy_from_local destination_dir
        index_html = File.read File.join(destination_dir, 'pretty_url_path', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end
  end

  describe '#has_tag?' do
    let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo',
                       'sha' => 'some-sha', 'directory' => 'pretty_url_path'} }
    let(:repo) { DocRepo.new(repo_hash, nil, nil, nil) }
    let(:my_tag) { '#hashtag' }

    before do
      GitClient.any_instance.stub(:validate_authorization)
      GitClient.any_instance.stub(:tags).and_return(tags)
    end

    context 'when a tag has been applied' do
      let(:tags) do
        [OpenStruct.new(name: my_tag)]
      end

      it 'is true when checking that tag' do
        repo.should have_tag(my_tag)
      end
      it 'is false when checking a different tag' do
        repo.should_not have_tag('nobody_uses_me')
      end
    end

    context 'when no tag has been applied' do
      let(:tags) { [] }

      it 'is false' do
        repo.should_not have_tag(my_tag)
      end
    end
  end

  describe '#tag_with' do
    let(:repo_sha) { 'some-sha' }
    let(:repo_hash) do
      {
          'github_repo' => 'my-docs-org/my-docs-repo',
          'sha' => repo_sha,
          'directory' => 'pretty_url_path'
      }
    end
    let(:repo) { DocRepo.from_remote repo_hash: repo_hash }
    let(:my_tag) { '#hashtag' }

    before do
      GitClient.any_instance.stub(:validate_authorization)
      GitClient.any_instance.stub(:commits).with(repo.full_name)
        .and_return([OpenStruct.new(sha: repo_sha)])
    end

    it 'should apply a tag' do
      GitClient.any_instance.should_receive(:create_tag!)
        .with(repo.full_name, my_tag, repo.target_ref)

      repo.tag_with(my_tag)
    end
  end

  describe '#copy_from_*' do
    let(:repo_name) { 'org/my-docs-repo' }
    let(:some_sha) { 'some-sha' }
    let(:repo_hash) { {'github_repo' => repo_name, 'sha' => some_sha} }
    let(:repo) { DocRepo.new(repo_hash, nil, local_repo_dir, nil) }
    let(:destination_dir) { tmp_subdir('destination') }
    let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }

    describe '_local' do
      let(:copy_to) { repo.copy_from_local destination_dir }
      let(:local_repo_dir) { tmp_subdir 'local_repo_dir' }

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
      end

      context 'and the local repo is not there' do
        before do
          expect(File.exist? repo_dir).to be_false
        end
        it 'returns false' do
          expect(copy_to).to be_false
        end
      end
    end

    describe '_remote' do
      let(:copy_to) { repo.copy_from_remote destination_dir }
      let(:local_repo_dir) { nil }

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
end


