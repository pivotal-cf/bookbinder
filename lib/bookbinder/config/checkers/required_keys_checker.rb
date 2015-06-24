require_relative '../configuration'

module Bookbinder
  module Config
    module Checkers
      class RequiredKeysChecker
        MissingRequiredKeyError = Class.new(RuntimeError)

        def check(config)
          missing_keys = []

          Config::Configuration::CONFIG_REQUIRED_KEYS.each do |required_key|
            begin
              config.public_send(required_key)
            rescue KeyError
              missing_keys.push(required_key)
            end
          end

          if missing_keys.length > 0
            MissingRequiredKeyError.new("Your config.yml is missing required key(s). Required keys are #{missing_keys.join(", ")}.")
          end
        end
      end
    end
  end
end
