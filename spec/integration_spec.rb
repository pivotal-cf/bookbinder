require 'spec_helper'

describe '$ bookbinder' do
  include_context 'tmp_dirs'

  around_with_fixture_repo do |spec|
    spec.run
  end

  before do
    config = YAML.load(File.read('./config.yml'))
    config.delete('cred_repo')
    File.write('./config.yml', config.to_yaml)
  end

  describe 'publish' do
    describe 'local' do
      it 'generates a rack app' do
        `#{GEM_ROOT}/bin/bookbinder publish local`

        index_html = File.read File.join('final_app', 'public', 'foods', 'sweet','index.html')
        index_html.should include 'This is a Markdown Page'
      end

      it 'respects subnav includes' do
        `#{GEM_ROOT}/bin/bookbinder publish local`

        dogs_index = File.read File.join('final_app', 'public', 'dogs', 'index.html')
        dogs_index.should include 'Woof'
        dogs_index.should_not include 'Cabbage'
        dogs_index.should_not include 'Sputnik'
        dogs_index.should_not include 'Cherry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'savory', 'index.html')
        papers_index.should include 'Cabbage'
        papers_index.should_not include 'Sputnik'
        papers_index.should_not include 'Woof'
        papers_index.should_not include 'Strawberry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        papers_index.should include 'Strawberry'
        papers_index.should_not include 'Sputnik'
        papers_index.should_not include 'Woof'
        papers_index.should_not include 'Spinach'
      end
    end
  end
end
