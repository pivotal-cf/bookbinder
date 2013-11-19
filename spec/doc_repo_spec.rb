require 'spec_helper'

describe DocRepo do

  include ShellOut
  include_context 'tmp_dirs'

  describe '#download_and_unzip' do
    let(:destination_dir) { tmp_subdir 'middleman_source_dir' }
    let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
    let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo', 'sha' => 'some-sha'} }
    let(:repo) { DocRepo.new(repo_hash, nil, nil, local_repo_dir) }

    context 'when told to look for repos on github' do
      let(:local_repo_dir) { nil }

      it 'downloads and unzips the repo' do
        stub_request(:get, 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz').to_return(
            :body => zipped_markdown_repo, :headers => { 'Content-Type' => 'application/x-gzip' }
        )
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end

    context 'when told to look for repos locally' do
      let(:local_repo_dir) { File.join('spec', 'fixtures', 'markdown_repos') }

      it 'finds them in the supplied directory' do
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'my-docs-repo', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end

      context 'when the repo is not present in the supplied directory' do
        let(:repo_hash) { {'github_repo' => 'my-docs-org/my-non-existent-docs-repo'} }
        it 'gracefully skips repos that are not present in the supplied directory' do
          repo.copy_to destination_dir
          new_entries = Dir.entries(destination_dir) - ['..', '.']
          expect(new_entries.size).to eq(0)
        end
      end
    end

    context 'when a custom directory is specified for the repo' do
      let(:local_repo_dir) { File.join('spec', 'fixtures', 'markdown_repos') }
      let(:repo_hash) { {'github_repo' => 'my-docs-org/my-docs-repo',
                         'sha' => 'some-sha', 'directory' => 'pretty_url_path'} }

      it 'puts the repo into that directory' do
        stub_request(:get, 'https://github.com/my-docs-org/my-docs-repo/archive/some-sha.tar.gz').to_return(
            :body => zipped_markdown_repo, :headers => { 'Content-Type' => 'application/x-gzip' }
        )
        repo.copy_to destination_dir
        index_html = File.read File.join(destination_dir, 'pretty_url_path', 'index.html.md')
        index_html.should include 'This is a Markdown Page'
      end
    end
  end

  describe '#copy_to' do
    let(:repo_hash) { {'github_repo' => 'org/my-docs-repo', 'sha' => 'some-sha'} }
    let(:repo) { DocRepo.new(repo_hash, nil, nil, local_repo_dir) }
    let(:destination_dir) { tmp_subdir('destination') }
    let(:repo_dir) { File.join(local_repo_dir, 'my-docs-repo') }

    def copy_to
      repo.copy_to destination_dir
    end

    context 'when given a local repo dir' do
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

    context 'when not given a local repo dir' do
      let(:zipped_markdown_repo) { MarkdownRepoFixture.tarball 'my-docs-repo', 'some-sha' }
      let(:local_repo_dir) { nil }

      before do
        zipped_repo_url = 'https://github.com/org/my-docs-repo/archive/some-sha.tar.gz'
        stub_request(:get, zipped_repo_url).to_return(
            :body => zipped_markdown_repo, :headers => {'Content-Type' => 'application/x-gzip'}
        )
      end

      it 'retrieves the repo from github' do
        copy_to
        expect(File.exist? File.join(destination_dir, 'my-docs-repo', 'index.html.md')).to be_true
      end

      it 'returns true' do
        expect(copy_to).to be_true
      end

    end
  end
end