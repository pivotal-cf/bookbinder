require_relative '../bookbinder/dita_section'

module Bookbinder
  class LocalDitaProcessor
    DitaToHtmlLibraryFailure = Class.new(RuntimeError)

    def initialize(sheller, path_to_dita_ot_library)
      @sheller = sheller
      @path_to_dita_ot_library = path_to_dita_ot_library
    end

    def process(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        absolute_path_to_ditamap = File.join dita_section.path_to_local_repo, dita_section.ditamap_location
        classpath = "#{path_to_dita_ot_library}/lib/xercesImpl.jar:" +
                    "#{path_to_dita_ot_library}/lib/xml-apis.jar:" +
                    "#{path_to_dita_ot_library}/lib/resolver.jar:" +
                    "#{path_to_dita_ot_library}/lib/commons-codec-1.4.jar:$DITA_DIR/lib/icu4j.jar:" +
                    "#{path_to_dita_ot_library}/lib/saxon/saxon9-dom.jar:" +
                    "#{path_to_dita_ot_library}/lib/saxon/saxon9.jar:target/classes:" +
                    "#{path_to_dita_ot_library}:" +
                    "#{path_to_dita_ot_library}/lib/:" +
                    "#{path_to_dita_ot_library}/lib/dost.jar"
        out_dir = File.join to, dita_section.directory
        command = "export DITA_DIR=#{path_to_dita_ot_library}; " +
                  "export CLASSPATH=#{classpath}; " +
                  "ant -f #{path_to_dita_ot_library} " +
                  "-Dbasedir='/' " +
                  "-Doutput.dir=#{out_dir} " +
                  "-Dtranstype='htmlhelp' " +
                  "-Dargs.input=#{absolute_path_to_ditamap}"

        begin
          sheller.run_command(command)
        rescue Sheller::ShelloutFailure
          raise DitaToHtmlLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
              'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
              'that your DITA-specific keys/values in config.yml are set, ' +
              'and that your DITA toolkit is correctly configured.'

        end
        File.join to, dita_section.directory
      end
    end

    private

    attr_reader :sheller, :path_to_dita_ot_library
  end
end
