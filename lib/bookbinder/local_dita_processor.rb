require_relative '../bookbinder/dita_section'

module Bookbinder
  class LocalDitaProcessor
    def initialize(sheller, path_to_dita_ant_script)
      @sheller = sheller
      @path_to_dita_ant_script = path_to_dita_ant_script
    end

    def process(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        absolute_path_to_ditamap = File.join dita_section.path_to_local_repo, dita_section.ditamap_location
        out_dir = File.join to, dita_section.directory
        sheller.run_command("ant -f #{path_to_dita_ant_script} -Dditamap_location=#{absolute_path_to_ditamap} -Dout_dir=#{out_dir}", false)

        File.join to, dita_section.directory
      end
    end

    private
    attr_reader :sheller, :path_to_dita_ant_script
  end
end