module Bookbinder
  class DitaCommandCreator
    MissingDitaOTFlagValue = Class.new(RuntimeError)

    def initialize(path_to_dita_ot_library)
      @path_to_dita_ot_library = path_to_dita_ot_library
    end

    def convert_to_pdf_command(dita_section, dita_flags: nil, write_to: nil)
      "export CLASSPATH=#{classpath}; " +
      "ant -f #{path_to_dita_ot_library} " +
      unduplicated_flags(
        write_to: write_to,
        dita_flags: dita_flags,
        ditamap_path: dita_section.path_to_preprocessor_attribute('ditamap_location'),
        ditaval_path: dita_section.path_to_preprocessor_attribute('ditaval_location'),
        default_transtype: 'pdf2'
      )
    end

    def convert_to_html_command(dita_section, dita_flags: nil, write_to: nil)
      "export CLASSPATH=#{classpath}; " +
      "ant -f #{path_to_dita_ot_library} " +
        unduplicated_flags(
          write_to: write_to,
          dita_flags: dita_flags,
          ditamap_path: dita_section.path_to_preprocessor_attribute('ditamap_location'),
          ditaval_path: dita_section.path_to_preprocessor_attribute('ditaval_location'),
          default_transtype: 'tocjs'
      )
    end

    private

    def unduplicated_flags(write_to: nil, ditamap_path: nil, ditaval_path: nil, dita_flags: nil, default_transtype: nil)
      arg_flags = {
          'output.dir' => write_to,
          'args.input' => ditamap_path,
      }.merge(filter(ditaval_path))
      all_flags = arg_flags.merge(base_flags(default_transtype: default_transtype).merge(optional_flags(dita_flags)))
      format(all_flags)
    end

    def filter(ditaval_path)
      ditaval_path ? { 'args.filter' => ditaval_path } : {}
    end

    def base_flags(default_transtype: nil)
      {
          'basedir' => '/',
          'transtype' => default_transtype,
          'dita.temp.dir' => '/tmp/bookbinder_dita',
          'generate.copy.outer' => '2',
          'outer.control' => 'warn'
      }
    end

    def optional_flags(flags_str)
      flags = flags_str ? flags_str.split(" ") : []
      {}.tap do |h|
        flags.each do |f|
          k,v = f.split('=')
          h[k] = v
          raise MissingDitaOTFlagValue.new("The DITA-flag '#{k}' that you passed is missing a value. Please pass your DITA option in the format '#{k}=<value>'.") unless v
        end
      end
    end

    def format(flags)
      flags.inject("") do |res, f|
        k,v = f
        res + "-D#{k}='#{stripped_flag_value v}' "
      end
    end

    def stripped_flag_value(v)
      v.to_s.gsub(/['|"]/, "")
    end

    def classpath
      "#{path_to_dita_ot_library}/lib/xercesImpl.jar:" +
      "#{path_to_dita_ot_library}/lib/xml-apis.jar:" +
      "#{path_to_dita_ot_library}/lib/resolver.jar:" +
      "#{path_to_dita_ot_library}/lib/commons-codec-1.4.jar:" +
      "#{path_to_dita_ot_library}/lib/icu4j.jar:" +
      "#{path_to_dita_ot_library}/lib/saxon/saxon9-dom.jar:" +
      "#{path_to_dita_ot_library}/lib/saxon/saxon9.jar:target/classes:" +
      "#{path_to_dita_ot_library}:" +
      "#{path_to_dita_ot_library}/lib/:" +
      "#{path_to_dita_ot_library}/lib/dost.jar"
    end

    attr_reader :path_to_dita_ot_library
  end
end
