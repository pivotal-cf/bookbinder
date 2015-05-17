require_relative '../../../../lib/bookbinder/ingest/working_copy'
require_relative '../../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Repositories
    describe SectionRepository do
      let(:logger) { double('deprecated logger interface').as_null_object }
      let(:repository) { SectionRepository.new(logger) }

      describe 'getting a section' do
        it 'logs the name of the repository' do
          expect(logger).to receive(:log).with(/foo\/book/)

          repository.get_instance(
            {'repository' => {'name' => 'foo/book'}},
            working_copy: Ingest::WorkingCopy.new(repo_dir: 'some/repo/dir',
                                                  full_name: 'org/repo',
                                                  copied_to: 'path/to/repo',
                                                  directory: 'repo')
          ) { |*args| Section.new(*args) }
        end

        context 'if the repo is not a hash' do
          let(:local_repo_dir) { 'spec/fixtures/repositories' }
          it 'raises a not a hash error message' do
            expect {
              repository.get_instance({ 'repository' => 'foo/definitely-not-around' },
                                      working_copy: Ingest::WorkingCopy.new(copied_to: 'path/to/repo'),
                                      destination_dir: local_repo_dir) { |*args| Section.new(*args) }
            }.to raise_error(RuntimeError,
                             "section repository 'foo/definitely-not-around' is not a hash")
          end
        end

        context 'if the repo name is missing' do
          let(:local_repo_dir) { 'spec/fixtures/repositories' }
          it 'raises a missing name key error message' do
            expect {
              repository.get_instance({ 'repository' => { some_key: 'test' }},
                                      working_copy: Ingest::WorkingCopy.new(copied_to: 'path/to/repo'),
                                      destination_dir: local_repo_dir) { |*args| Section.new(*args) }
            }.to raise_error(RuntimeError,
                             "section repository '{:some_key=>\"test\"}' missing name key")
          end
        end
      end
    end
  end
end
