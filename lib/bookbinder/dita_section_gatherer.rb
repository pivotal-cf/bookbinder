module Bookbinder
  class DitaSectionGatherer
    def initialize(version_control_system)
      @version_control_system = version_control_system
    end

    def gather(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        p "Copying..."
        version_control_system.clone("git@github.com:#{dita_section.full_name}",
                                     dita_section.directory,
                                     path: to)
        p "Cloned #{dita_section.full_name}"

        DitaSection.new(File.join(to, dita_section.directory),
                        dita_section.ditamap_location,
                        dita_section.full_name,
                        dita_section.target_ref,
                        dita_section.directory)
        end
    end

    private

    attr_reader :version_control_system

  end
end