require 'net/http'

module Bookbinder
  class DitaOTInstaller
    UnpackingError = Class.new(RuntimeError)

    def install_dita
      tar('-jxf', download(AntDownload.new))
      dita_ot = DitaOTDownload.new
      tar('-zxf', download(dita_ot))
      spec_root.join("utilities", dita_ot.dir)
    end

    def download(resource)
      utilities_path = spec_root.join("utilities")
      utilities_path.mkpath

      destination = utilities_path.join(resource.tarball_filename)

      data = Net::HTTP.get(URI(resource.tarball_url))
      File.open(destination, 'w') do |f|
        f.write(data)
      end
      destination
    end

    def tar(opts, path)
      Dir.chdir(File.dirname(path)) do
        unless system("tar #{opts} #{path}")
          raise UnpackingError.new("Failed to unpack #{path} with the command `tar #{opts} #{path}`")
        end
      end
    end

    def java_home
      if File.exist?('/usr/libexec/java_home')
        `/usr/libexec/java_home -v '1.6*'`.chomp
      else
        ENV['JAVA_HOME']
      end
    end

    def spec_root
      Pathname(File.expand_path("../..", __FILE__))
    end
  end

  class AntDownload
    def tarball_url
      "http://archive.apache.org/dist/ant/binaries/#{tarball_filename}"
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
      "https://master.dl.sourceforge.net/project/dita-ot/DITA-OT%20Stable%20Release/DITA%20Open%20Toolkit%201.7/DITA-OT#{version}_full_easy_install_bin.tar.gz"
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

end
