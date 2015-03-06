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
      old_env = ENV.clone
      ENV.update(
        'PATH_TO_DITA_OT_LIBRARY' => install_dita.to_s,
        'JAVA_HOME' => java_home,
        'PATH' => "#{spec_root.join("utilities", "apache-ant-1.9.4", "bin")}:#{ENV['PATH']}"
      )
      begin
        example.run
      ensure
        ENV = old_env
      end
    end

    it "processes the DITA into HTML in the output dir" do
      book_dir = tmp_subdir("repositories/dita-book")
      book_config = YAML.load_file(book_dir.join('config.yml'))
      tmp_subdir("repositories/dita-section")

      Dir.chdir(book_dir) do
        swallow_stdout do
          Cli.new.run(%w(bind local --verbose))
        end
      end

      expected_section_name = 'dita-section'
      expect(book_config['dita_sections'].first['directory']).
        to eq(expected_section_name)

      path = Pathname("./final_app/public/#{expected_section_name}/index.html")
      frag = Nokogiri::HTML.fragment(path.read)
      expect(frag.css("ul>li>a")).to be_any
    end

    def install_dita
      tar('-jxf', download(AntDownload.new))
      dita_ot = DitaOTDownload.new
      tar('-zxf', download(dita_ot))
      spec_root.join("utilities", dita_ot.dir)
    end

    def download(resource)
      spec_root.join("utilities").tap(&:mkpath).
        join(resource.tarball_filename).tap do |destination|
        `curl -s #{resource.tarball_url} > #{destination}` unless destination.exist?
      end
    end

    def tar(opts, path)
      `cd #{File.dirname(path)}; tar #{opts} #{path}; cd -`
    end

    def spec_root
      Pathname(File.expand_path("../..", __FILE__))
    end

    class AntDownload
      def tarball_url
        "http://mirror.ox.ac.uk/sites/rsync.apache.org//ant/binaries/#{tarball_filename}"
      end

      def tarball_filename
        "apache-ant-#{version}-bin.tar.bz2"
      end

      def dir
        "apache-ant-#{version}"
      end

      def version
        "1.9.4"
      end
    end

    class DitaOTDownload
      def tarball_url
        "http://heanet.dl.sourceforge.net/project/dita-ot/DITA-OT%20Stable%20Release/DITA%20Open%20Toolkit%201.7/DITA-OT#{version}_full_easy_install_bin.tar.gz"
      end

      def tarball_filename
        "dita.tar.gz"
      end

      def dir
        "DITA-OT#{version}"
      end

      def version
        "1.7.5"
      end
    end

    def java_home
      if File.exist?('/usr/libexec/java_home')
        `/usr/libexec/java_home -v '1.6*'`.chomp
      else
        ENV['JAVA_HOME']
      end
    end
  end
end
