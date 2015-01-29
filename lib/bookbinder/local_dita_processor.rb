require_relative '../bookbinder/dita_section'

module Bookbinder
  class LocalDitaProcessor
    def initialize(sheller, path_to_dita_ant_script)
      @sheller = sheller
      @path_to_dita_ant_script = path_to_dita_ant_script
    end

    def process(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        relative_path_to_ditamap = File.join "../../../../../workspace/pubtools/pubtools-dita-book-pivotalcf/output/tmp/dita_sections/#{dita_section.directory}", dita_section.ditamap_location
        dita_dir = '/Users/pivotal/Downloads/oxygenAuthor/frameworks/dita/DITA-OT'
        classpath = "#{dita_dir}/lib/xercesImpl.jar:#{dita_dir}/lib/xml-apis.jar:#{dita_dir}/lib/resolver.jar:#{dita_dir}/lib/commons-codec-1.4.jar:$DITA_DIR/lib/icu4j.jar:#{dita_dir}/lib/saxon/saxon9-dom.jar:#{dita_dir}/lib/saxon/saxon9.jar:target/classes:#{dita_dir}:#{dita_dir}/lib/:#{dita_dir}/lib/dost.jar"
        out_dir = File.join '../../../../../workspace/pubtools/pubtools-dita-book-pivotalcf/output/tmp/processed_dita', dita_section.directory
        p out_dir
        sheller.run_command("export DITA_DIR=#{dita_dir}; " +
                            "export CLASSPATH=#{classpath}; " +
                            "ant -f #{path_to_dita_ant_script} " +
                            "-Doutput.dir=#{out_dir} -Dtranstype='htmlhelp' -Dargs.input=#{relative_path_to_ditamap}",
                            false)

        File.join to, dita_section.directory
      end
    end

    private
    attr_reader :sheller, :path_to_dita_ant_script
  end
end
