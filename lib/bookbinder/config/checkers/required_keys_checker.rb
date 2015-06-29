require_relative '../configuration'

module Bookbinder
  module Config
    module Checkers
      class RequiredKeysChecker
        MissingRequiredKeyError = Class.new(RuntimeError)

        def check(config)
          missing_keys = Config::Configuration::CONFIG_REQUIRED_KEYS.reject { |key| config.has_option?(key) }
          if missing_keys.any?
            MissingRequiredKeyError.new("Your config.yml is missing required key(s). Required keys are #{missing_keys.join(", ")}.")
          end
        end
      end
    end
  end
end
