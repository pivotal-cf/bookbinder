require_relative '../bookbinder/values/dita_section'

module Bookbinder
  class DitaToHtmlConverter
    DitaToHtmlLibraryFailure = Class.new(RuntimeError)

    def initialize(sheller, path_to_dita_ot_library)
      @sheller = sheller
      @path_to_dita_ot_library = path_to_dita_ot_library
    end

    def convert_to_html(dita_section, write_to: nil)
      classpath = "#{path_to_dita_ot_library}/lib/xercesImpl.jar:" +
                  "#{path_to_dita_ot_library}/lib/xml-apis.jar:" +
                  "#{path_to_dita_ot_library}/lib/resolver.jar:" +
                  "#{path_to_dita_ot_library}/lib/commons-codec-1.4.jar:" +
                  "#{path_to_dita_ot_library}/lib/icu4j.jar:" +
                  "#{path_to_dita_ot_library}/lib/saxon/saxon9-dom.jar:" +
                  "#{path_to_dita_ot_library}/lib/saxon/saxon9.jar:target/classes:" +
                  "#{path_to_dita_ot_library}:" +
                  "#{path_to_dita_ot_library}/lib/:" +
                  "#{path_to_dita_ot_library}/lib/dost.jar"
      command = "export CLASSPATH=#{classpath}; " +
                "ant -f #{path_to_dita_ot_library} " +
                "-Dbasedir='/' " +
                "-Doutput.dir=#{write_to} " +
                "-Dtranstype='tocjs' " +
                "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
                "-Dgenerate.copy.outer='2' " +
                "-Dargs.input=#{dita_section.absolute_path_to_ditamap} "

      if dita_section.absolute_path_to_ditaval
        command += "-Dargs.filter=#{dita_section.absolute_path_to_ditaval} "
      end

      unless sheller.run_command(command).success?
        raise DitaToHtmlLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
          'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
          'that your DITA-specific keys/values in config.yml are set, ' +
          'and that your DITA toolkit is correctly configured.'

      end
    end

    private

    attr_reader :sheller, :path_to_dita_ot_library
  end
end
