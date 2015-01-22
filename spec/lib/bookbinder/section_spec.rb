require_relative '../../../lib/bookbinder/section'

module Bookbinder
  describe Section do

    describe '#subnav_template' do
      let(:repo) { Section.new(SupportedFormats::Markdown,
                               'directory',
                               'full name',
                               copied = true,
                               subnav_template_name,
                               'path/to/repository') }

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
