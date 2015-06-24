module Bookbinder
  module Config
    module Checkers
      class RepositoryNamePresenceChecker
        MissingRepositoryNameError = Class.new(RuntimeError)

        def check(config)
          failures = config.sections.reject do |section|
            section.repo_name
          end

          if failures.empty?
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
