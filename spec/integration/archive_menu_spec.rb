require_relative '../../lib/bookbinder/cli'
require_relative '../helpers/use_fixture_repo'
require_relative '../helpers/middleman'

module Bookbinder
  describe "a book with an archive menu" do
    include SpecHelperMethods

    use_fixture_repo('archive-menu-book')

    let(:book_config) {
      YAML.load_file(
        File.expand_path(
          '../../fixtures/repositories/archive-menu-book/config.yml',
          __FILE__))
    }

    it "exposes archive variables via a template helper method" do
      silence_io_streams do
        Cli.new.run(%w(bind local))
      end

      doc = Nokogiri::HTML(
        File.read(
          tmpdir.join(*%w(
            repositories archive-menu-book final_app public index.html))))

      expect(doc.css("#menu_title").text).to eq(configured_menu_title)
      expect(doc.css("#version_0").text).to eq(first_configured_version)
      expect(doc.css("#path_0").text).to eq(first_configured_path)
    end

    def configured_menu_title
      book_config['archive_menu'].first
    end

    def first_configured_version
      book_config['archive_menu'][1].keys.first
    end

    def first_configured_path
      "/#{book_config['archive_menu'][1].values.first}"
    end
  end
end
