require_relative '../values/section'
require_relative '../values/product_info'

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

          if section_config.dependent_sections.any?
            section_config.dependent_sections.map do |dependent_config|
              unless dependent_config.no_docs?
                streams[:success].puts("Gathering #{dependent_config.repo_name}")
                cloner.call(source_repo_name: dependent_config.repo_name,
                            source_ref: ref_override || dependent_config.repo_ref,
                            destination_parent_dir: "#{destination_dir}/#{section_config.desired_directory_name}",
                            destination_dir_name: dependent_config.desired_directory_name)
              end
            end
          end

          Section.new(
            working_copy.path,
            working_copy.full_name,
            section_config.desired_directory_name,
            section_config.subnav_template,
            section_config.subnav_name,
            section_config.preprocessor_config,
            section_config.at_repo_path,
            section_config.repo_name,
            working_copy.ref,
            section_config.pdf_output_filename,
            section_config.product_info
          )
        end
      end
    end
  end
end
