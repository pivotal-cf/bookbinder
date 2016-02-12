module Bookbinder
  module Config
    module Checkers
      class DitamapPresenceChecker
        DitamapLocationError = Class.new(RuntimeError)

        def check(config)
          if any_sections_missing_ditamaps?(config.sections)
            DitamapLocationError.new(
              "You must have a 'ditamap_location' for each key in dita_sections."
            )
          end
        end

        private

        def any_sections_missing_ditamaps?(sections)
          sections.any? do |s|
            if s.preprocessor_config.has_key?('ditamap_location')
              s.preprocessor_config['ditamap_location'].nil? || s.preprocessor_config['ditamap_location'].empty?
            end
          end
        end
      end
    end
  end
end
