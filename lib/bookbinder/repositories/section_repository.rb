require 'tmpdir'
require_relative '../deprecated_logger'
require_relative '../values/section'

module Bookbinder
  module Repositories
    class SectionRepository
      def initialize(logger)
        @logger = logger
      end

      def get_instance(section_config,
                       working_copy: nil,
                       destination_dir: nil,
                       &build)
        logger.log "Gathering #{section_config.repo_name.cyan}"
        Section.new(
          working_copy.copied_to,
          working_copy.full_name,
          working_copy.copied?,
          destination_dir,
          working_copy.directory,
          section_config.subnav_template
        )
      end

      private

      attr_reader :logger
    end
  end
end
