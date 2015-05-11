module Bookbinder
  class Configuration

    CURRENT_SCHEMA_VERSION = '1.0.0'
    STARTING_SCHEMA_VERSION = '1.0.0'

    ConfigSchemaUnsupportedError = Class.new(RuntimeError)

    attr_reader :schema_version, :schema_major_version, :schema_minor_version, :schema_patch_version

    def initialize(config)
      @config = config
    end

    CONFIG_REQUIRED_KEYS = %w(book_repo public_host)
    CONFIG_OPTIONAL_KEYS = %w(archive_menu layout_repo versions cred_repo)

    CONFIG_REQUIRED_KEYS.each do |method_name|
      define_method(method_name) do
        config.fetch(method_name)
      end
    end

    CONFIG_OPTIONAL_KEYS.each do |method_name|
      define_method(method_name) do
        config[method_name]
      end
    end

    def sections
      config.fetch('sections', [])
    end

    def dita_sections
      config.fetch('dita_sections', {})
    end

    def has_option?(key)
      @config.has_key?(key)
    end

    def template_variables
      config.fetch('template_variables', {})
    end

    def ==(o)
      o.class == self.class && o.instance_variable_get(:@config) == @config
    end

    alias_method :eql?, :==

    private

    attr_reader :config
  end
end
