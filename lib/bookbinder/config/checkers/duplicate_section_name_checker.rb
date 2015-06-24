require_relative '../../ingest/destination_directory'

module Bookbinder
  module Config
    module Checkers
      class DuplicateSectionNameChecker
        DuplicateSectionNameError = Class.new(RuntimeError)

        def check(config)
          if duplicate_section_names?(config)
            DuplicateSectionNameError.new error_message
          end
        end

        private

        def duplicate_section_names?(config)
          directory_names = config.sections.map {|section|
            Ingest::DestinationDirectory.new(section.repo_name,
                                             section.desired_directory_name)
          }
          directory_names.length != directory_names.uniq.length
        end

        def error_message
          <<-ERROR
    Duplicate repository names are not allowed.
          ERROR
        end
      end
    end
  end
end
