require 'yaml'
require_relative '../../../helpers/redirection'
require_relative '../../../helpers/use_fixture_repo'

module Bookbinder
  describe 'bind local' do
    use_fixture_repo

    before do
      config = YAML.load(File.read('./config.yml'))
      config.delete('cred_repo')
      File.write('./config.yml', config.to_yaml)
    end

    let(:gem_root) { File.absolute_path('../../../..', __dir__) }

    include Bookbinder::Redirection

    it 'generates a rack app' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder publish local`
      end

      index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
      expect(index_html).to include 'This is a Markdown Page'
    end

    it 'respects subnav includes' do
      swallow_stdout do
        `#{gem_root}/install_bin/bookbinder publish local`
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
