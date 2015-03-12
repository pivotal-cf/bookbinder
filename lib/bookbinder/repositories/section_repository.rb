require 'tmpdir'

module Bookbinder
  module Repositories
    class SectionRepository
      def initialize(logger)
        @logger = logger
      end

      def get_instance(attributes,
                       vcs_repo: nil,
                       destination_dir: Dir.mktmpdir,
                       &build)
        repository_config = attributes['repository']
        raise "section repository '#{repository_config}' is not a hash" unless repository_config.is_a?(Hash)
        raise "section repository '#{repository_config}' missing name key" unless repository_config['name']
        logger.log "Gathering #{repository_config['name'].cyan}"
        build[vcs_repo.copied_to,
              vcs_repo.full_name,
              vcs_repo.copied?,
              attributes['subnav_template'],
              destination_dir,
              vcs_repo.directory]
      end

      private

      attr_reader :logger
    end
  end
end
