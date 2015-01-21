require_relative '../../../lib/bookbinder/repositories/section_repository'
require_relative '../../../lib/bookbinder/section'
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/nil_logger'

module Bookbinder
  describe Section do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:vcs_accessor) { double('vcs_accessor') }
    let(:repository) {
      Repositories::SectionRepository.new(
        logger,
        store: {},
        build: ->(*args) { Section.new(*args) },
        git_accessor: vcs_accessor
      )
    }

    describe '#subnav_template' do
      let(:repo) { Section.new(double(:repo), subnav_template_name, 'path/to/repository') }

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
end
