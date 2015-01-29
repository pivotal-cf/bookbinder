module Bookbinder
  class DitaSectionGatherer
    def initialize(version_control_system, view_updater)
      @version_control_system = version_control_system
      @view_updater = view_updater
    end

    def gather(dita_sections, to: nil)
      dita_sections.map do |dita_section|
        view_updater.log "Gathering " + "#{dita_section.full_name}".cyan
        version_control_system.clone("git@github.com:#{dita_section.full_name}",
                                     dita_section.directory,
                                     path: to)

        DitaSection.new(File.join(to, dita_section.directory),
                        dita_section.ditamap_location,
                        dita_section.full_name,
                        dita_section.target_ref,
                        dita_section.directory)
        end
    end

    private

    attr_reader :version_control_system, :view_updater

  end
end