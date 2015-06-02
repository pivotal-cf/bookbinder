require 'tmpdir'
require_relative '../deprecated_logger'
require_relative '../values/section'

module Bookbinder
  module Ingest
    class SectionRepository
      def initialize(logger, cloner)
        @logger = logger
        @cloner = cloner
      end

      def fetch(configured_sections: [],
                destination_dir: nil,
                ref_override: nil)
        configured_sections.map do |section_config|
          logger.log "Gathering #{section_config.repo_name.cyan}"
          working_copy = cloner.call(source_repo_name: section_config.repo_name,
                                     source_ref: ref_override || section_config.repo_ref,
                                     destination_parent_dir: destination_dir,
                                     destination_dir_name: section_config.desired_directory_name)
          Section.new(
            working_copy.path,
            working_copy.full_name,
            destination_dir,
            section_config.desired_directory_name,
            section_config.subnav_template,
            section_config.preprocessor_config
          )
        end
      end

      private

      attr_reader :logger, :cloner
    end
  end
end
