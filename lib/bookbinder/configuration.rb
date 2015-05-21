require_relative 'ingest/repo_identifier'
require_relative 'config/section_config'

module Bookbinder
  class Configuration
    CURRENT_SCHEMA_VERSION = '1.0.0'
    STARTING_SCHEMA_VERSION = '1.0.0'

    ConfigSchemaUnsupportedError = Class.new(RuntimeError)

    attr_reader :schema_version, :schema_major_version, :schema_minor_version, :schema_patch_version

    class << self
      def parse(input_config)
        new(symbolize_keys(input_config).
            merge(expand_repo_identifiers(input_config)).
            merge(sections: combined_sections(input_config)))
      end

      private

      def symbolize_keys(h)
        h.reduce({}) {|acc, (k, v)| acc.merge(k.to_sym => v) }
      end

      def expand_repo_identifiers(input_config)
        input_config.select {|k, _| k.match(/_repo$/)}.
          reduce({}) {|h, (k, v)| h.merge(:"#{k}_url" => Ingest::RepoIdentifier.new(v))}
      end

      def combined_sections(input_config)
        (regular_sections(input_config) + dita_sections(input_config)).
          map { |section| Config::SectionConfig.new(section) }
      end

      def regular_sections(input_config)
        input_config['sections'] || []
      end

      def dita_sections(input_config)
        (input_config['dita_sections'] || []).map { |dita_section|
          dita_section.merge(
            'preprocessor_config' => {
              'ditamap_location' => dita_section['ditamap_location'],
              'ditaval_location' => dita_section['ditaval_location']
            },
            'subnav_template' => 'dita_subnav'
          ).reject { |k, _|
            %w(ditamap_location ditaval_location).include?(k)
          }
        }
      end
    end

    def initialize(config)
      @config = config
    end

    CONFIG_REQUIRED_KEYS = %w(book_repo public_host)
    CONFIG_OPTIONAL_KEYS = %w(archive_menu book_repo_url cred_repo cred_repo_url layout_repo layout_repo_url sections)

    CONFIG_REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        config.fetch(method_name.to_sym)
      end
    end

    CONFIG_OPTIONAL_KEYS.each do |method_name|
      define_method(method_name) do
        config[method_name.to_sym]
      end
    end

    def template_variables
      config.fetch(:template_variables, {})
    end

    def versions
      config.fetch(:versions, [])
    end

    def merge(other_configuration)
      Configuration.new(config.merge(other_configuration.instance_variable_get(:@config)))
    end

    def merge_sections(incoming_sections)
      merge(Configuration.new(sections: sections + incoming_sections))
    end

    def has_option?(key)
      !!config[key.to_sym]
    end

    def ==(o)
      o.class == self.class && o.instance_variable_get(:@config) == @config
    end

    alias_method :eql?, :==

    private

    attr_reader :config
  end
end
