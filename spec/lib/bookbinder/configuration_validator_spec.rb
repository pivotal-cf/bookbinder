require 'spec_helper'

module Bookbinder
  describe ConfigurationValidator do
    let(:logger) { NilLogger.new }
    let(:bookbinder_schema_version) { '1.0.0' }
    let(:starting_schema_version) { '1.0.0' }
    let(:file_system_accessor) { double 'fileSystemAccessor', file_exist?: true }
    let(:subject) { ConfigurationValidator.new(logger, file_system_accessor) }

    describe 'validating the configuration hash' do
      context 'when there is a minimal valid configuration hash' do
        it 'returns nil' do
          config_hash = {
            'book_repo' => 'some-repo',
            'public_host' => 'domain',
            'sections' => []
          }

          expect(subject.valid?(config_hash,
                                bookbinder_schema_version,
                                starting_schema_version)).to be_nil
        end
      end
    end
  end
end
