require_relative '../../../lib/bookbinder/git_hub_repository'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/tmp_dirs'

module Bookbinder
  describe GitHubRepository do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:github_token) { 'blahblah' }
    let(:git_client) { GitClient.new(access_token: github_token) }
    let(:repo_name) { 'great_org/dogs-repo' }
    let(:section_hash) { {'repository' => {'name' => repo_name}} }
    let(:destination_dir) { tmp_subdir('output') }
    let(:local_repo_dir) { 'spec/fixtures/repositories' }
    let(:repository) { double GitHubRepository }

    def build(args)
      GitHubRepository.new(args)
    end

    before do
      allow(GitClient).to receive(:new).and_call_original
      allow(GitClient).to receive(:new).with(access_token: github_token).and_return(git_client)
    end

    it 'requires a full_name' do
      expect(
        build(logger: logger, github_token: github_token, full_name: '').
        full_name
      ).to eq('')

      expect {
        build(logger: logger, github_token: github_token)
      }.to raise_error(/full_name/)
    end

    describe '#tag_with' do
      let(:head_sha) { 'ha7f'*10 }

      it 'calls #create_tag! on the github instance variable' do
        expect(git_client).to receive(:head_sha).with('org/repo').and_return head_sha
        expect(git_client).to receive(:create_tag!).with('org/repo', 'the_tag_name', head_sha)

        build(logger: logger, github_token: github_token, full_name: 'org/repo').tag_with('the_tag_name')
      end
    end

    describe '#tag_with' do
      let(:repo_sha) { 'some-sha' }
      let(:repo) { build(logger: logger,
                         github_token: github_token,
                         full_name: 'my-docs-org/my-docs-repo',
                         local_repo_dir: '') }
      let(:my_tag) { '#hashtag' }

      before do
        allow(git_client).to receive(:validate_authorization)
        allow(git_client).to receive(:commits).with(repo.full_name)
                             .and_return([double(sha: repo_sha)])
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
      let(:repository) { build(logger: logger, github_token: github_token, full_name: full_name, local_repo_dir: local_repo_dir) }

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
  end
end
