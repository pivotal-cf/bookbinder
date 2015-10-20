module Bookbinder
  module Config
    module Checkers
      class SubnavsChecker
        MissingRequiredKeyError = Class.new(RuntimeError)
        MissingSubnavsKeyError = Class.new(RuntimeError)
        MissingSubnavNameError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if section_subnav_names.count > 0
            if config.subnavs.empty?
               MissingSubnavsKeyError.new("You must specify at least one subnav under the subnavs key in config.yml")
            elsif missing_subnavs.count != 0
              MissingSubnavNameError.new("Your config.yml is missing required subnav names under the subnavs key. Required subnav names are #{missing_subnavs.join(", ")}.")
            elsif invalid_subnavs.any?
              MissingRequiredKeyError.new("Your config.yml is missing required key(s) for subnavs #{invalid_subnav_names}. Required keys are #{required_subnav_keys.join(", ")}.")
            end
          end
        end

        attr_reader :config

        private

        def invalid_subnavs
          config.subnavs.map {|subnav_config| subnav_config unless subnav_config.valid? }
        end

        def invalid_subnav_names
          invalid_subnavs.map(&:subnav_name).join(", ")
        end

        def missing_subnavs
          section_subnav_names - config.subnavs.map(&:subnav_name)
        end

        def required_subnav_keys
          Bookbinder::Config::SubnavConfig::CONFIG_REQUIRED_KEYS
        end

        def section_subnav_names
          config.sections.map(&:subnav_name).compact.uniq
        end
      end
    end
  end
end
