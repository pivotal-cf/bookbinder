require_relative '../../../../lib/bookbinder/config/validator'

module Bookbinder
  module Config
    describe Validator do
      let(:logger) { double('logger').as_null_object }
      let(:bookbinder_schema_version) { '1.0.0' }
      let(:starting_schema_version) { '1.0.0' }
      let(:file_system_accessor) { double 'fileSystemAccessor', file_exist?: true }
      let(:subject) { Validator.new(logger, file_system_accessor) }

      describe 'validating the configuration hash' do
        context 'when there is a minimal valid configuration hash' do
          it 'returns no exceptions' do
            config_hash = {
              'book_repo' => 'some-repo',
              'public_host' => 'domain',
              'sections' => []
            }

            expect(subject.exceptions(config_hash)).to be_empty
          end
        end
      end
    end
  end
end
