require 'spec_helper'

describe '$ bookbinder' do
  use_fixture_repo

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  describe 'publish' do
    describe 'local' do
      it 'generates a rack app', integration: true do
        silence_io_streams do
          `#{GEM_ROOT}/bin/bookbinder publish local`
        end

        index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        expect(index_html).to include 'This is a Markdown Page'
      end

      it 'respects subnav includes', integration: true do
        silence_io_streams do
          `#{GEM_ROOT}/bin/bookbinder publish local`
        end

        dogs_index = File.read File.join('final_app', 'public', 'dogs', 'index.html')
        expect(dogs_index).to include 'Woof'
        expect(dogs_index).not_to include 'Cabbage'
        expect(dogs_index).not_to include 'Sputnik'
        expect(dogs_index).not_to include 'Cherry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'savory', 'index.html')
        expect(papers_index).to include 'Cabbage'
        expect(papers_index).not_to include 'Sputnik'
        expect(papers_index).not_to include 'Woof'
        expect(papers_index).not_to include 'Strawberry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        expect(papers_index).to include 'Strawberry'
        expect(papers_index).not_to include 'Sputnik'
        expect(papers_index).not_to include 'Woof'
        expect(papers_index).not_to include 'Spinach'
      end
    end
  end
end
