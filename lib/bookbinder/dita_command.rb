require_relative '../bookbinder/values/dita_section'

module Bookbinder
  class DitaCommand
    def initialize(path_to_dita_ot_library)
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
      command
    end

    private

    attr_reader :path_to_dita_ot_library
  end
end
