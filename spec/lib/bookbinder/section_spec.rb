require_relative '../../../lib/bookbinder/section'

module Bookbinder
  describe Section do
    describe "repo path" do
      it "wraps the input in a Pathname, for easier manipulation" do
        expect(Section.new('some/path/to/repo').
               path_to_repository.join('or/something')).
        to eq(Pathname('some/path/to/repo/or/something'))
      end

      it "even wraps a nil repo path, so that e.g. file existence checks fail" do
        expect(Section.new.path_to_repository.join('foo')).
          to eq(Pathname('foo'))
      end
    end

    describe '#subnav_template' do
      let(:repo) { Section.new('directory',
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
