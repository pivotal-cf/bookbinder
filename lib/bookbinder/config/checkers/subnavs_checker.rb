module Bookbinder
  module Config
    module Checkers
      class SubnavsChecker
        MissingSubnavsKeyError = Class.new(RuntimeError)
        MissingSubnavNameError = Class.new(RuntimeError)

        def check(config)
          if section_subnav_names(config).count > 0
            if config.subnavs.nil?
               MissingSubnavsKeyError.new("You must specify at least one subnav under the subnavs key in config.yml")
            elsif missing_subnavs(config).count != 0
              MissingSubnavNameError.new("Your config.yml is missing required subnav names under the subnavs key. Required subnav names are #{missing_subnavs(config).join(", ")}.")
            end
          end
        end

        private

        def missing_subnavs(config)
          section_subnav_names(config) - config.subnavs.map(&:name)
        end

        def section_subnav_names(config)
          config.sections.map(&:subnav_name).compact.uniq
        end
      end
    end
  end
end
