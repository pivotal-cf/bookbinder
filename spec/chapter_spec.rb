require 'spec_helper'

describe Chapter do
  include ShellOut
  include_context 'tmp_dirs'

  describe '.get_instance' do
    let(:local_repo_dir) { '/dev/null' }
    before do
      stub_github_for 'foo/book'
      stub_github_for 'foo/dogs-repo'
    end

    context 'when called more than once' do
      it 'always returns the same instance for the same arguments' do
        first_instance = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/book'}, local_repo_dir: local_repo_dir)
        second_instance = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/book'}, local_repo_dir: local_repo_dir)
        expect(first_instance).to be(second_instance)
      end

      it 'returns different instances for different repo names' do
        first_instance = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/dogs-repo'}, local_repo_dir: local_repo_dir)
        second_instance = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/book'}, local_repo_dir: local_repo_dir)

        expect(first_instance).not_to be(second_instance)
      end

      it 'returns different instances for different modes' do
        local_code_repo = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/book'}, local_repo_dir: 'spec/fixtures/repositories')
        remote_code_repo = Chapter.get_instance(repo_hash: {'github_repo' => 'foo/book'})

        expect(local_code_repo).not_to be(remote_code_repo)
      end
    end

    context 'in local mode' do
      context 'if the repo is present, locally' do
        let(:local_repo_dir) { 'spec/fixtures/repositories' }

        it 'copies repos from local directory' do
          expect(Chapter.get_instance(repo_hash: {'github_repo' => 'foo/code-example-repo'}, local_repo_dir: local_repo_dir)).to be_copied
        end
      end

      context 'if the repo is missing' do
        let(:local_repo_dir) { '/dev/null' }

        it 'logs a warning' do
          expect(BookbinderLogger).to receive(:log).with /skipping \(not found\)/
          Chapter.get_instance(repo_hash: {'github_repo' => 'foo/definitely-not-around'}, local_repo_dir: local_repo_dir)
        end
      end
    end
  end

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

      let(:zipped_markdown_repo) { RepoFixture.tarball 'dogs-repo', sha }
      let(:destination_dir) { tmp_subdir('output') }
      let(:repo_name) { 'great_org/dogs-repo' }
      let(:download_url) { "https://github.com/great_org/dogs-repo/archive/#{sha}.tar.gz" }

      context 'when no SHA is provided' do
        let(:sha) { 'master' }
        let(:repo_hash) { {'github_repo' => repo_name} }

        it 'uses "master" to make requests for the archive link' do
          GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: sha).and_return(download_url)
          Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir)
        end

        it 'copies the repo from github' do
          GitClient.any_instance.stub(:archive_link).and_return download_url
          Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir)
          expect(File.exist? File.join(destination_dir, 'dogs-repo', 'index.html.md.erb')).to be_true
        end

        context 'and a target_tag is provided' do
          let(:target_tag) { 'oh-dot-three-dot-oh' }

          it 'uses the tag to make requests for the archive link' do
            GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: target_tag).and_return(download_url)
            Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir, target_tag: target_tag)
          end
        end
      end

      context 'when a SHA is provided' do
        let(:sha) { 'this-is-the-commit-i-want' }
        let(:repo_hash) { {'github_repo' => repo_name, 'sha' => sha} }

        it 'uses the provided SHA to make requests for the archive link' do
          GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: sha).and_return download_url
          Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir)
        end

        it 'copies the repo from github' do
          GitClient.any_instance.stub(:archive_link).and_return download_url
          Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir)
          expect(File.exist? File.join(destination_dir, 'dogs-repo', 'index.html.md.erb')).to be_true
        end

        context 'and a target_tag is provided' do
          let(:target_tag) { 'oh-dot-three-dot-oh' }
          it 'uses the tag to make requests for the archive link' do
            GitClient.any_instance.should_receive(:archive_link).with(repo_name, ref: target_tag).and_return(download_url)
            Chapter.get_instance(repo_hash: repo_hash, destination_dir: destination_dir, target_tag: target_tag)
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
      Chapter.get_instance(repo_hash: {'github_repo' => 'crazy_family_of_mine/' + repo_name},
                           local_repo_dir: local_repo_dir,
                           destination_dir: destination_dir)
      expect(File.exist? File.join(destination_dir, repo_name, 'my_aunties_goat.txt')).to be_true
    end
  end

  describe '#subnav_template' do
    let(:repo) { Chapter.new(double(:repo), subnav_template_name) }

    context 'when the incoming template does not look like a partial file' do
      let(:subnav_template_name) { 'my_template' }

      it 'is unchanged' do
        expect(repo.subnav_template).to eq('my_template')
      end
    end

    context 'when the incoming template looks like a partial file' do
      let(:subnav_template_name) { '_my_tem.erbplate.erb' }

      it 'is trimmed' do
        expect(repo.subnav_template).to eq('my_tem.erbplate')
      end
    end

    context 'when the incoming template is not defined' do
      let(:subnav_template_name) { nil }

      it 'is nil' do
        expect(repo.subnav_template).to be_nil
      end
    end
  end
end
