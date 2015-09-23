require_relative '../values/section'

module Bookbinder
  module Ingest
    class SectionRepository
      def fetch(configured_sections: [],
                destination_dir: nil,
                ref_override: nil,
                cloner: nil,
                streams: nil)
        configured_sections.map do |section_config|
          streams[:success].puts("Gathering #{section_config.repo_name}")
          working_copy = cloner.call(source_repo_name: section_config.repo_name,
                                     source_ref: ref_override || section_config.repo_ref,
                                     destination_parent_dir: destination_dir,
                                     destination_dir_name: section_config.desired_directory_name)
          Section.new(
            working_copy.path,
            working_copy.full_name,
            section_config.desired_directory_name,
            section_config.subnav_template,
            section_config.preprocessor_config
          )
        end
      end
    end
  end
end
