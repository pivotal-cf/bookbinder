require_relative '../bookbinder/dita_section'

module Bookbinder
  class LocalDitaProcessor
    DitaLibraryFailure = Class.new(RuntimeError)

    def initialize(sheller, configuration_fetcher)
      @sheller = sheller
      @configuration_fetcher = configuration_fetcher
    end

    def process(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        absolute_path_to_ditamap = File.join dita_section.path_to_local_repo, dita_section.ditamap_location
        classpath = "#{path_to_dita_dir}/lib/xercesImpl.jar:" +
                    "#{path_to_dita_dir}/lib/xml-apis.jar:" +
                    "#{path_to_dita_dir}/lib/resolver.jar:" +
                    "#{path_to_dita_dir}/lib/commons-codec-1.4.jar:$DITA_DIR/lib/icu4j.jar:" +
                    "#{path_to_dita_dir}/lib/saxon/saxon9-dom.jar:" +
                    "#{path_to_dita_dir}/lib/saxon/saxon9.jar:target/classes:" +
                    "#{path_to_dita_dir}:" +
                    "#{path_to_dita_dir}/lib/:" +
                    "#{path_to_dita_dir}/lib/dost.jar"
        out_dir = File.join to, dita_section.directory
        command = "export DITA_DIR=#{path_to_dita_dir}; " +
                  "export CLASSPATH=#{classpath}; " +
                  "ant -f #{path_to_dita_dir} " +
                  "-Dbasedir='/' " +
                  "-Doutput.dir=#{out_dir} " +
                  "-Dtranstype='htmlhelp' " +
                  "-Dargs.input=#{absolute_path_to_ditamap}"

        begin
          sheller.run_command(command)
        rescue Sheller::ShelloutFailure
          raise DitaLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
              'Please check your DITA-specific keys/values in config.yml and ensure that your DITA toolkit is correctly configured.'

        end
        File.join to, dita_section.directory
      end
    end

    private

    attr_reader :sheller

    def path_to_dita_dir
      @path_to_dita_dir ||= @configuration_fetcher.fetch_config.path_to_dita_ot_library
    end
  end
end
