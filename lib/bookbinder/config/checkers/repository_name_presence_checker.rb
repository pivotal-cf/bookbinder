module Bookbinder
  module Config
    module Checkers
      class RepositoryNamePresenceChecker
        MissingRepositoryNameError = Class.new(RuntimeError)

        def check(config)
          all_sections = config['sections'].to_a + config['dita_sections'].to_a
          failures = all_sections.map do |section|
            if !section['repository'] || !section['repository']['name']
              true
            end
          end

          if failures.compact.empty?
            nil
          else
            MissingRepositoryNameError.new error_message
          end
        end

        private

        def error_message
          <<-ERROR
    Cannot locate a specific section.
    All sections must provide the section 'name' key under the 'repository' key:

    sections:
      - repository:
          name: 'your-org/your-repo'
          ERROR
        end
      end
    end
  end
end
