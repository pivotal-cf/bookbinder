require_relative '../../../lib/bookbinder/config/dita_config_generator'
require_relative '../ingest/destination_directory'
require_relative '../ingest/repo_identifier'
require_relative 'section_config'
require_relative 'product_config'

module Bookbinder
  module Config
    class Configuration
      class << self
        def parse(input_config)
          section_configs = to_section_configs(combined_sections(input_config))
          parse_sections(input_config, section_configs)
        end

        protected

        def parse_sections(input_config, section_configs)
          new(symbolize_keys(input_config).
              merge(expand_repo_identifiers(input_config)).
              merge(sections: section_configs))
        end

        def symbolize_keys(h)
          h.reduce({}) {|acc, (k, v)| acc.merge(k.to_sym => v) }
        end

        def expand_repo_identifiers(input_config)
          input_config.select {|k, _| k.match(/_repo$/)}.
            reduce({}) {|h, (k, v)| h.merge(:"#{k}_url" => Ingest::RepoIdentifier.new(v))}
        end

        def to_section_configs sections
          sections.map { |section| Config::SectionConfig.new(section) }
        end

        private

        def combined_sections(input_config)
          regular_sections(input_config) + dita_sections(input_config)
        end

        def regular_sections(input_config)
          input_config['sections'] || []
        end

        def dita_sections(input_config)
          (input_config['dita_sections'] || []).map { |dita_section|
            DitaConfigGenerator.new(dita_section).to_hash
          }
        end
      end

      def initialize(config)
        @config = config
        @products = assemble_products || []
      end

      CONFIG_REQUIRED_KEYS = %w(book_repo public_host)
      CONFIG_OPTIONAL_KEYS = %w(archive_menu book_repo_url cred_repo cred_repo_url repo_link_enabled repo_links feedback_enabled layout_repo layout_repo_ref layout_repo_url sections)

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

      def broken_link_exclusions
        config.fetch(:broken_link_exclusions, /(?!.*)/)
      end

      def template_variables
        config.fetch(:template_variables, {})
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

      def elastic_search?
        config.fetch(:elastic_search, false)
      end

      def ==(o)
        o.class == self.class && o.instance_variable_get(:@config) == @config
      end

      alias_method :eql?, :==

      attr_reader :products

      private

      def assemble_products
        if config[:products]
          config[:products].map do |product|
            Config::ProductConfig.new(product)
          end
        end
      end

      attr_reader :config
    end
  end
end
