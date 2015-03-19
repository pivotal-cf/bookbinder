require_relative '../configuration'

module Bookbinder
  class RequiredKeysChecker
    MissingRequiredKeyError = Class.new(RuntimeError)
    SectionAbsenceError = Class.new(RuntimeError)

    def check(config)
      missing_keys = []

      Configuration::CONFIG_REQUIRED_KEYS.map do |required_key|
        config_keys = config.keys
        unless config_keys.include?(required_key)
          missing_keys.push(required_key)
        end
      end

      if missing_keys.length > 0
        MissingRequiredKeyError.new("Your config.yml is missing required key(s). Required keys are #{missing_keys.join(", ")}.")
      elsif !config['sections'] && !config['dita_sections']
        SectionAbsenceError.new error_message
      end
    end

    private

    def error_message
      <<-ERROR
Error in bind command: cannot locate your sections to bind.
Must specify at least one of 'sections' and/or 'dita_sections' in config.yml:

sections:
  - repository:
      name: 'your-org/your-repo'

dita_sections:
  - repository:
      name: 'dita-org/dita-repo'
    ditamap_location: 'example.ditamap'
      ERROR
    end
  end
end
