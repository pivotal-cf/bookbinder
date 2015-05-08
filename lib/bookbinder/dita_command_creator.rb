require_relative '../bookbinder/values/dita_section'

module Bookbinder
  class DitaCommandCreator
    def initialize(path_to_dita_ot_library)
      @path_to_dita_ot_library = path_to_dita_ot_library
    end

    def convert_to_html_command(dita_section, dita_flags: nil, write_to: nil)
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
                unduplicated_flags(write_to: write_to,
                                   dita_flags: dita_flags,
                                   ditamap_path: dita_section.absolute_path_to_ditamap,
                                   ditaval_path: dita_section.absolute_path_to_ditaval)
      command
    end

    private

    def unduplicated_flags(write_to: nil, ditamap_path: nil, ditaval_path: nil, dita_flags: dita_flags)
      arg_flags = {
          'output.dir' => write_to,
          'args.input' => ditamap_path,
          'args.filter' => ditaval_path || ""
      }
      all_flags = arg_flags.merge(base_flags.merge(optional_flags dita_flags))
      format(all_flags)
    end

    def base_flags
      {
          'basedir' => '/',
          'transtype' => 'tocjs',
          'dita.temp.dir' => '/tmp/bookbinder_dita',
          'generate.copy.outer' => '2',
          'outer.control' => 'warn'
      }
    end

    def optional_flags(flags_str)
      flags = flags_str ? flags_str.split(" ") : []
      flags.inject({}) do |h, f|
        k,v = f.split('=')
        h[k] = v
        h
      end
    end

    def format(flags)
      flags.inject("") do |res, f|
        k,v = f
        res += "-D#{k}='#{stripped_flag_value v}' "
      end
    end

    def stripped_flag_value(v)
      v.gsub(/['|"]/, "")
    end

    attr_reader :path_to_dita_ot_library
  end
end
