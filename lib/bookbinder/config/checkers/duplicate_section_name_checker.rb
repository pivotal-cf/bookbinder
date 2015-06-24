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
          sections = config['sections'].to_a + config['dita_sections'].to_a
          directory_names = sections.map {|section|
            Ingest::DestinationDirectory.new(section['repository']['name'],
                                             section['directory'])
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
