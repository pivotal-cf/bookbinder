require_relative 'ingest/repo_identifier'
require_relative 'config/section_config'

module Bookbinder
  class Configuration
    class << self
      def parse(input_config)
        new(symbolize_keys(input_config).merge(
          input_config.reduce({}) {|acc_config, (k, v)|
            new_key, transform = transforms(input_config)[k]
            if new_key
              acc_config.merge(new_key => transform[v])
            else
              acc_config
            end
          }.merge(
            sections: all_sections(input_config).map { |section| Config::SectionConfig.new(section) },
          )))
      end

      private

      def symbolize_keys(h)
        h.reduce({}) {|acc, (k, v)|
          acc.merge(k.to_sym => v)
        }
      end

      def transforms(input_config)
        {
          'book_repo' => [:book_repo_url, ->(v) { Ingest::RepoIdentifier.new(v) }],
          'cred_repo' => [:cred_repo_url, ->(v) { Ingest::RepoIdentifier.new(v) }],
          'layout_repo' => [:layout_repo_url, ->(v) { Ingest::RepoIdentifier.new(v) }],
          'template_variables' => [:template_variables, ->(_) { input_config.fetch('template_variables', {}) }],
          'versions' => [:versions, ->(_) { input_config.fetch('versions', []) }]
        }
      end

      def all_sections(input_config)
        (input_config['sections'] || []) + (input_config['dita_sections'] || []).map { |dita_section|
          dita_section.
            merge('preprocessor_config' => { 'ditamap_location' => dita_section['ditamap_location'],
                                             'ditaval_location' => dita_section['ditaval_location'] },
            'subnav_template' => 'dita_subnav').
            reject { |k, v| %w(ditamap_location ditaval_location).include?(k) }
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
