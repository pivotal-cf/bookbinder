module Bookbinder
  class Configuration
    CURRENT_SCHEMA_VERSION = '1.0.0'
    STARTING_SCHEMA_VERSION = '1.0.0'
    DEFAULT_VCS_PREFIX = 'git@github.com:'

    ConfigSchemaUnsupportedError = Class.new(RuntimeError)

    attr_reader :schema_version, :schema_major_version, :schema_minor_version, :schema_patch_version

    def initialize(config)
      @config = config
    end

    CONFIG_REQUIRED_KEYS = %w(book_repo public_host)
    CONFIG_OPTIONAL_KEYS = %w(archive_menu layout_repo cred_repo)

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

    def merge(other)
      if Configuration === other
        Configuration.new(config.merge(other.instance_variable_get(:@config)))
      else
        Configuration.new(config.merge(other))
      end
    end

    def book_repo_url
      vcs_url(book_repo)
    end

    def cred_repo_url
      vcs_url(cred_repo)
    end

    def sections
      config.fetch('sections', []).map {|section|
        section.merge('repo_url' => vcs_url(section['repository']['name']))
      }
    end

    def dita_sections
      config.fetch('dita_sections', {})
    end

    def has_option?(key)
      config.has_key?(key)
    end

    def template_variables
      config.fetch('template_variables', {})
    end

    def versions
      config.fetch('versions', [])
    end

    def ==(o)
      o.class == self.class && o.instance_variable_get(:@config) == @config
    end

    alias_method :eql?, :==

    private

    attr_reader :config

    def vcs_url(repo_identifier)
      if repo_identifier.include?(':')
        repo_identifier
      else
        "#{DEFAULT_VCS_PREFIX}#{repo_identifier}"
      end
    end
  end
end
