require_relative '../configuration'

module Bookbinder
  module Config
    module Imprint
      class Configuration < Config::Configuration
        class << self
          def parse(input_config)
            section_configs = to_section_configs(pdf_sections(input_config))
            parse_sections(input_config, section_configs)
          end

          private

          def pdf_sections(input_config)
            (input_config['pdf_sections'] || []).map { |pdf_section|
              DitaConfigGenerator.new(pdf_section).to_hash
            }
          end
        end
      end
    end
  end
end
