require_relative '../ingest/destination_directory'
require_relative '../ingest/repo_identifier'
require_relative 'section_config'

module Bookbinder
  module Config
    class Configuration
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
          dita_sections = input_config['dita_sections']
          (dita_sections || []).map { |dita_section|
            dita_section.merge(
              'preprocessor_config' => {
                'ditamap_location' => dita_section['ditamap_location'],
                'ditaval_location' => dita_section['ditaval_location']
              },
              'subnav_template' => dita_subnav_template(dita_sections, dita_section)
            ).reject { |k, _|
              %w(ditamap_location ditaval_location).include?(k)
            }
          }
        end

        def dita_subnav_template(all_sections, current_section)
          subnav_sections = all_sections.select { |section| section['ditamap_location'] }
          if subnav_sections.empty?
            nil
          elsif subnav_sections.one?
            "dita_subnav"
          else
            subnav_section = subnav_sections.include?(current_section) ? current_section : subnav_sections.first
            (
              ["dita_subnav"] +
              Array(
                Ingest::DestinationDirectory.new(
                  subnav_section.fetch('repository', {})['name'], subnav_section['directory'])
              )
            ).join('_')
          end
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

      def ==(o)
        o.class == self.class && o.instance_variable_get(:@config) == @config
      end

      alias_method :eql?, :==

      private

      attr_reader :config
    end
  end
end
