require 'tmpdir'

module Bookbinder
  module Repositories
    class SectionRepository
      def initialize(logger)
        @logger = logger
      end

      def get_instance(section_config,
                       working_copy: nil,
                       destination_dir: Dir.mktmpdir,
                       &build)
        repository_config = section_config['repository']
        raise "section repository '#{repository_config}' is not a hash" unless repository_config.is_a?(Hash)
        raise "section repository '#{repository_config}' missing name key" unless repository_config['name']
        logger.log "Gathering #{repository_config['name'].cyan}"
        build[working_copy.copied_to,
              working_copy.full_name,
              working_copy.copied?,
              section_config['subnav_template'],
              destination_dir,
              working_copy.directory]
      end

      private

      attr_reader :logger
    end
  end
end
