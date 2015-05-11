require_relative '../../../lib/bookbinder/git_hub_repository'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/tmp_dirs'

module Bookbinder
  describe GitHubRepository do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:github_token) { 'blahblah' }
    let(:repo_name) { 'great_org/dogs-repo' }
    let(:section_hash) { {'repository' => {'name' => repo_name}} }
    let(:destination_dir) { tmp_subdir('output') }
    let(:local_repo_dir) { 'spec/fixtures/repositories' }
    let(:repository) { double GitHubRepository }

    def build(args)
      GitHubRepository.new(args)
    end

    it 'requires a full_name' do
      expect(
        build(logger: logger, full_name: '').
        full_name
      ).to eq('')

      expect {
        build(logger: logger)
      }.to raise_error(/full_name/)
    end

    describe '#update_local_copy' do
      let(:local_repo_dir) { tmpdir }
      let(:full_name) { 'org/repo-name' }
      let(:repo_dir) { File.join(local_repo_dir, 'repo-name') }
      let(:repository) { build(logger: logger, full_name: full_name, local_repo_dir: local_repo_dir) }

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
