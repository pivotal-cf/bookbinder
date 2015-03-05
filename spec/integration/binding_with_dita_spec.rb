require 'nokogiri'
require_relative '../../lib/bookbinder/cli'
require_relative '../helpers/middleman'
require_relative '../helpers/redirection'
require_relative '../helpers/use_fixture_repo'

module Bookbinder
  describe "binding a book with local DITA sections" do
    extend SpecHelperMethods
    include Redirection

    use_fixture_repo('dita-book')

    around do |example|
      old_path = ENV['PATH_TO_DITA_OT_LIBRARY']
      ENV['PATH_TO_DITA_OT_LIBRARY'] = install_dita.to_s
      begin
        example.run
      ensure
        ENV['PATH_TO_DITA_OT_LIBRARY'] = old_path
      end
    end

    it "processes the DITA into HTML in the output dir" do
      book_dir = tmp_subdir("repositories/dita-book")
      book_config = YAML.load_file(book_dir.join('config.yml'))
      tmp_subdir("repositories/dita-section")

      Dir.chdir(book_dir) do
        Cli.new.run(%w(bind local --verbose))
      end

      expected_section_name = 'dita-section'
      expect(book_config['dita_sections'].first['directory']).
        to eq(expected_section_name)

      path = Pathname("./final_app/public/#{expected_section_name}/index.html")
      frag = Nokogiri::HTML.fragment(path.read)
      expect(frag.css("ul>li>a")).to be_any
    end

    def install_dita
      dita_tarball_path = download(dita_tarball_url, dita_tarball_filename)
      tar('-zxf', dita_tarball_path)
      spec_root.join("utilities", dita_dir)
    end

    def download(archive_url, archive_filename)
      spec_root.join("utilities").tap(&:mkpath).
        join(archive_filename).tap do |destination|
        `curl #{archive_url} > #{destination}` unless destination.exist?
      end
    end

    def tar(opts, path)
      `cd #{File.dirname(path)}; tar #{opts} #{path}; cd -`
    end

    def spec_root
      Pathname(File.expand_path("../..", __FILE__))
    end

    def dita_tarball_url
      "http://heanet.dl.sourceforge.net/project/dita-ot/DITA-OT%20Stable%20Release/DITA%20Open%20Toolkit%201.7/DITA-OT1.7.5_full_easy_install_bin.tar.gz"
    end

    def dita_tarball_filename
      "dita.tar.gz"
    end

    def dita_dir
      "DITA-OT#{dita_version}"
    end

    def dita_version
      "1.7.5"
    end
  end
end
