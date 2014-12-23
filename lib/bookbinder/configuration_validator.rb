module Bookbinder
  class ConfigurationValidator
    DuplicateSectionNameError = Class.new(RuntimeError)

    def initialize(logger)
      @logger = logger
    end

    def valid?(config_hash, bookbinder_schema_version, starting_schema_version)
      @config_hash = config_hash
      raise 'Your config.yml appears to be empty. Please check and try again.' unless config_hash

      @bookbinder_schema_version = bookbinder_schema_version
      schema_major_version, schema_minor_version, schema_patch_version = bookbinder_schema_version.split('.')

      if user_schema_version.nil?
        raise Configuration::ConfigSchemaUnsupportedError.new schema_now_required_message unless bookbinder_schema_version == starting_schema_version
      elsif user_major_version > schema_major_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_minor_version > schema_minor_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_patch_version > schema_patch_version
        raise Configuration::ConfigSchemaUnsupportedError.new unrecognized_schema_version_message
      elsif user_major_version < schema_major_version
        raise Configuration::ConfigSchemaUnsupportedError.new incompatible_schema_message
      elsif user_minor_version < schema_minor_version
        @logger.warn nonbreaking_schema_message_for("minor")
      elsif user_patch_version < schema_patch_version
        @logger.warn nonbreaking_schema_message_for("patch")
      end

      if duplicate_section_names?
        raise DuplicateSectionNameError
      end

      true
    end

    private

    def duplicate_section_names?
      directory_names = @config_hash['sections'].map {|section| section['directory']}
      directory_names.length != directory_names.uniq.length
    end

    def user_schema_version
      @config_hash['schema_version']
    end

    def user_major_version
      user_schema_version.split('.').first
    end

    def user_minor_version
      user_schema_version.split('.')[1]
    end

    def user_patch_version
      user_schema_version.split('.').last
    end

    def schema_now_required_message
      "[ERROR] Bookbinder now requires a certain schema. Please see README and provide a schema version."
    end

    def incompatible_schema_message
      "[ERROR] Your config.yml format, schema version #{user_schema_version}, is older than this version of Bookbinder can support. Please update your config.yml keys and format to version #{@bookbinder_schema_version} and try again."
    end

    def unrecognized_schema_version_message
      "[ERROR] The config schema version #{user_schema_version} is unrecognized by this version of Bookbinder. The latest schema version is #{@bookbinder_schema_version}."
    end

    def nonbreaking_schema_message_for(version_level)
      "[WARNING] Your schema is valid, but there exists a new #{version_level} version. Consider updating your config.yml."
    end
end
end
