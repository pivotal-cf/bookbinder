require_relative 'local_dita_section_gatherer'
require_relative 'remote_dita_section_gatherer'

module Bookbinder
  class DitaSectionGathererFactory
    def initialize(version_control_system, view_updater)
      @version_control_system = version_control_system
      @view_updater = view_updater
    end

    def produce(source_location, output_locations)
      if source_location == 'github'
        RemoteDitaSectionGatherer.new(version_control_system, view_updater, output_locations)
      else
        LocalDitaSectionGatherer.new(output_locations)
      end
    end

    private

    attr_reader :version_control_system, :view_updater
  end
end
