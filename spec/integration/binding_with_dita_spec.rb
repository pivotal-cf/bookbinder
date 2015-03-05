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
      old_path = ENV['PATH']
      old_java_home = ENV['JAVA_HOME']
      ENV['PATH_TO_DITA_OT_LIBRARY'] = install_dita.to_s
      ENV['JAVA_HOME'] = java_home
      ENV['PATH'] = "#{spec_root.join("utilities", "apache-ant-1.9.4", "bin")}:#{ENV['PATH']}"
      begin
        example.run
      ensure
        ENV['PATH_TO_DITA_OT_LIBRARY'] = old_path
        ENV['PATH'] = old_path
        ENV['JAVA_HOME'] = old_java_home
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
      ant_tarball_path = download(ant_tarball_url, ant_tarball_filename)
      tar('-jxf', ant_tarball_path)
      ant = spec_root.join("utilities", ant_dir, "bin", "ant")

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

    def ant_tarball_url
      "http://mirror.ox.ac.uk/sites/rsync.apache.org//ant/binaries/#{ant_tarball_filename}"
    end

    def ant_dir
      "apache-ant-#{ant_version}"
    end

    def ant_tarball_filename
      "apache-ant-#{ant_version}-bin.tar.bz2"
    end

    def ant_version
      "1.9.4"
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

    def java_home
      `/usr/libexec/java_home -v '1.6*'`.chomp
    end

  end
end
