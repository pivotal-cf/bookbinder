require_relative '../../lib/bookbinder/cli'
require_relative '../../lib/bookbinder/ingest/git_accessor'
require_relative '../helpers/middleman'
require_relative '../helpers/use_fixture_repo'

module Bookbinder
  describe "a book with archive menus" do
    extend SpecHelperMethods

    use_fixture_repo('archive-menu-book')

    before_all_in_fixture_repo('archive-menu-book') do
      silence_io_streams do
        Bookbinder::CLI.start(%w(bind local --verbose))
      end
    end

    def get_doc(path)
      Nokogiri::HTML(
        File.read(
          tmpdir.
          join(*%w(repositories archive-menu-book final_app public)).
          join(path)))
    end

    context "when on a book page" do
      it "exposes archive variables from the book" do
        doc = get_doc('index.html')

        expect(doc.css("#menu_title").text).to eq(first_book_version)
        expect(doc.css("#version_0").text).to eq(second_book_version)
        expect(doc.css("#path_0").text).to eq(second_book_version_path)
      end
    end

    context "when on a section with a special archive menu in its config" do
      it "exposes archive variables from the section" do
        doc = get_doc('per-repo-archive-menu-section-2/index.html')

        expect(doc.css("#menu_title").text).to eq(first_section_version)
        expect(doc.css("#version_0").text).to eq(second_section_version)
        expect(doc.css("#path_0").text).to eq(second_section_version_path)
      end
    end

    context "when on a section without its own config" do
      it "exposes archive variables from the book" do
        doc = get_doc('per-repo-archive-menu-section-1/index.html')

        expect(doc.css("#menu_title").text).to eq(first_book_version)
        expect(doc.css("#version_0").text).to eq(second_book_version)
        expect(doc.css("#path_0").text).to eq(second_book_version_path)
      end
    end

    context "when on a section with its own config, but no archive menu stanza" do
      it "exposes archive variables from the section" do
        doc = get_doc('per-repo-archive-menu-section-3/index.html')

        expect(doc.css("#menu_title").text).to eq(first_book_version)
        expect(doc.css("#version_0").text).to eq(second_book_version)
        expect(doc.css("#path_0").text).to eq(second_book_version_path)
      end
    end

    def first_book_version
      book_config['archive_menu'].first
    end

    def second_book_version
      book_config['archive_menu'][1].keys.first
    end

    def second_book_version_path
      "/#{book_config['archive_menu'][1].values.first}"
    end

    def first_section_version
      section_config['archive_menu'].first
    end

    def second_section_version
      section_config['archive_menu'][1].keys.first
    end

    def second_section_version_path
      "/#{section_config['archive_menu'][1].values.first}"
    end

    def book_config
      @book_config ||= load_config('archive-menu-book', 'config.yml')
    end

    def section_config
      @section_config ||= load_config('per-repo-archive-menu-section-2', 'bookbinder.yml')
    end

    def load_config(repo_name, config_file)
      YAML.load_file(
        File.expand_path(
          "../../fixtures/repositories/#{repo_name}/#{config_file}",
          __FILE__))
    end
  end
end
