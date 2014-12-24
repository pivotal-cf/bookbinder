module Bookbinder

  class DuplicateSectionNameChecker
    def check(config)
      if duplicate_section_names?(config)
        ConfigurationValidator::DuplicateSectionNameError
      end
    end

    private

    def duplicate_section_names?(config)
      directory_names = config['sections'].map {|section| section['directory']}
      directory_names.length != directory_names.uniq.length
    end

  end

  class ArchiveMenuChecker
    def initialize(file_system_accessor)
      @file_system_accessor = file_system_accessor
    end

    def check(config)
      partial_location = './master_middleman/source/archive_menus/_default.erb'
      if config.has_key?("archive_menu") && config["archive_menu"].nil?
        ConfigurationValidator::ArchiveMenuNotDefinedError.new 'Did you mean to provide an archive menu value to display? If you use the archive_menu key, you must provide at least one value.'
      elsif archive_items(config).include?(nil)
        ConfigurationValidator::EmptyArchiveItemsError.new 'Did you forget to add a value to the archive_menu?'
      elsif config.has_key?("archive_menu") && !@file_system_accessor.file_exist?(partial_location)
        ConfigurationValidator::MissingArchiveMenuPartialError.new "You must provide a template partial named at #{partial_location}"
      end
    end

    private

    def archive_items(config)
      config.fetch('archive_menu', [])
    end

  end

  Version = Struct.new(:major, :minor, :patch) do
    class << self
      def parse(raw_version)
        if raw_version
          new(*raw_version.split('.'))
        else
          new(nil, nil, nil)
        end
      end
    end

    def valid?
      [major, minor, patch].all?(&:present?)
    end

    def to_s
      [major, minor, patch].compact.join('.')
    end
  end

  class VersionCheckerMessages
    def initialize(user_schema_version, bookbinder_schema_version)
      @user_schema_version = user_schema_version
      @bookbinder_schema_version = bookbinder_schema_version
    end

    def schema_now_required_message
      "[ERROR] Bookbinder now requires a certain schema. Please see README " +
        "and provide a schema version."
    end

    def incompatible_schema_message
      "[ERROR] Your config.yml format, schema version #{user_schema_version}, " +
        "is older than this version of Bookbinder can support. Please update " +
        "your config.yml keys and format to version #{bookbinder_schema_version} " +
        "and try again."
    end

    def unrecognized_schema_version_message
      "[ERROR] The config schema version #{user_schema_version} is " +
        "unrecognized by this version of Bookbinder. The latest schema version " +
        "is #{bookbinder_schema_version}."
    end

    private

    attr_reader :user_schema_version, :bookbinder_schema_version
  end

  class ConfigVersionChecker
    def initialize(bookbinder_schema_version, starting_schema_version, messages, logger)
      @bookbinder_schema_version = bookbinder_schema_version
      @starting_schema_version = starting_schema_version
      @messages = messages
      @logger = logger
    end

    def check(config)
      user_schema_version = Version.parse(config['schema_version'])
      if user_schema_version.valid?
        if user_schema_version.major > bookbinder_schema_version.major
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.minor > bookbinder_schema_version.minor
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.patch > bookbinder_schema_version.patch
          raise Configuration::ConfigSchemaUnsupportedError.new messages.unrecognized_schema_version_message
        elsif user_schema_version.major < bookbinder_schema_version.major
          raise Configuration::ConfigSchemaUnsupportedError.new messages.incompatible_schema_message
        elsif user_schema_version.minor < bookbinder_schema_version.minor
          @logger.warn nonbreaking_schema_message_for("minor")
        elsif user_schema_version.patch < bookbinder_schema_version.patch
          @logger.warn nonbreaking_schema_message_for("patch")
        end
      elsif bookbinder_schema_version != starting_schema_version
        raise Configuration::ConfigSchemaUnsupportedError.new messages.schema_now_required_message
      end
    end

    private

    attr_reader :bookbinder_schema_version, :starting_schema_version, :messages

    def nonbreaking_schema_message_for(version_level)
      "[WARNING] Your schema is valid, but there exists a new #{version_level} version. Consider updating your config.yml."
    end
  end

  class ConfigurationValidator
    DuplicateSectionNameError = Class.new(RuntimeError)
    MissingArchiveMenuPartialError = Class.new(RuntimeError)
    EmptyArchiveItemsError = Class.new(RuntimeError)
    ArchiveMenuNotDefinedError = Class.new(RuntimeError)

    def initialize(logger, file_system_accessor)
      @logger = logger
      @file_system_accessor = file_system_accessor
    end

    def valid?(config_hash, bookbinder_schema_version, starting_schema_version)
      raise 'Your config.yml appears to be empty. Please check and try again.' unless config_hash

      user_config_schema_version = config_hash['schema_version']
      exceptions = [
        ConfigVersionChecker.new(Version.parse(bookbinder_schema_version),
                                 Version.parse(starting_schema_version),
                                 VersionCheckerMessages.new(Version.parse(user_config_schema_version),
                                                         bookbinder_schema_version),
                                 @logger),
        DuplicateSectionNameChecker.new,
        ArchiveMenuChecker.new(@file_system_accessor)
      ].map do |checker|
        checker.check(config_hash)
      end
      exception = exceptions.compact.first
      raise exception if exception

      true
    end
  end
end
