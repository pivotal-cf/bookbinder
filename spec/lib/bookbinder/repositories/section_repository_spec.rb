require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/ingest/working_copy'
require_relative '../../../../lib/bookbinder/repositories/section_repository'

module Bookbinder
  module Repositories
    describe SectionRepository do
      let(:null_logger) { double('deprecated logger').as_null_object }

      it 'logs the name of the repository' do
        logger = double('deprecated logger interface')
        expect(logger).to receive(:log).with(%r{foo/book})

        SectionRepository.new(logger).get_instance(
          Config::SectionConfig.new('repository' => {'name' => 'foo/book'}),
          working_copy: Ingest::WorkingCopy.new(repo_dir: 'some/repo/dir',
                                                full_name: 'org/repo',
                                                copied_to: 'path/to/repo',
                                                directory: 'repo')
        )
      end
    end
  end
end
