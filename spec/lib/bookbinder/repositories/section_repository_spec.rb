require_relative '../../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../../lib/bookbinder/bookbinder_logger'
require_relative '../../../../lib/bookbinder/section'
require_relative '../../../../spec/helpers/nil_logger'
require_relative '../../../../spec/helpers/spec_git_accessor'

module Bookbinder
  module Repositories
    describe SectionRepository do
      let(:logger) { NilLogger.new }
      let(:repository) do
        SectionRepository.new(
            logger,
            store: {},
            build: ->(*args) { Section.new(*args) }
        )
      end

      describe 'getting a section' do
        context 'when requested more than once' do
          it 'always returns the same instance for the same arguments' do
            vcs_repo = double 'vcs_repo', path_to_local_repo: 'path/to/repo'
            first_instance = repository.get_instance({'repository' => {'name' => 'foo/book'}}, vcs_repo: vcs_repo)
            second_instance = repository.get_instance({'repository' => {'name' => 'foo/book'}}, vcs_repo: vcs_repo)
            expect(first_instance).to be(second_instance)
          end

          it 'returns different instances for different repo names' do
            vcs_repo = double 'vcs_repo', path_to_local_repo: 'path/to/repo'
            first_instance = repository.get_instance({'repository' => {'name' => 'foo/dogs-repo'}}, vcs_repo: vcs_repo)
            second_instance = repository.get_instance({'repository' => {'name' => 'foo/book'}}, vcs_repo: vcs_repo)
            expect(first_instance).not_to be(second_instance)
          end
        end

        it 'logs the name of the repository' do
          expect(logger).to receive(:log).with(/foo\/book/)

          vcs_repo = double 'vcs_repo', path_to_local_repo: 'path/to/repo'
          repository.get_instance({'repository' => {'name' => 'foo/book'}}, vcs_repo: vcs_repo)
        end

        context 'if the repo is not a hash' do
          let(:local_repo_dir) { 'spec/fixtures/repositories' }
          it 'raises a not a hash error message' do
            vcs_repo = double 'vcs_repo', path_to_local_repo: 'path/to/repo'
            expect {
              repository.get_instance({ 'repository' => 'foo/definitely-not-around' }, vcs_repo: vcs_repo, destination_dir: local_repo_dir)
            }.to raise_error(RuntimeError,
                             "section repository 'foo/definitely-not-around' is not a hash")
          end
        end

        context 'if the repo name is missing' do
          let(:local_repo_dir) { 'spec/fixtures/repositories' }
          it 'raises a missing name key error message' do
            vcs_repo = double 'vcs_repo', path_to_local_repo: 'path/to/repo'
            expect {
              repository.get_instance({ 'repository' => { some_key: 'test' }}, vcs_repo: vcs_repo, destination_dir: local_repo_dir)
            }.to raise_error(RuntimeError,
                             "section repository '{:some_key=>\"test\"}' missing name key")
          end
        end
      end
    end
  end
end
