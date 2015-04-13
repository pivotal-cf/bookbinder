require_relative 'validation_checkers/duplicate_section_name_checker'
require_relative 'validation_checkers/archive_menu_checker'
require_relative 'validation_checkers/config_version_checker'
require_relative 'validation_checkers/required_keys_checker'
require_relative 'validation_checkers/repository_name_presence_checker'
require_relative 'validation_checkers/dita_section_checker'

module Bookbinder
  class ConfigurationValidator
    def initialize(logger, file_system_accessor)
      @logger = logger
      @file_system_accessor = file_system_accessor
    end

    def valid?(config_hash, bookbinder_schema_version, starting_schema_version)
      user_config_schema_version = config_hash['schema_version']
      exceptions = [
        ConfigVersionChecker.new(Version.parse(bookbinder_schema_version),
                                 Version.parse(starting_schema_version),
                                 VersionCheckerMessages.new(Version.parse(user_config_schema_version),
                                                         bookbinder_schema_version),
                                 @logger),
        RequiredKeysChecker.new,
        DuplicateSectionNameChecker.new,
        RepositoryNamePresenceChecker.new,
        DitaSectionChecker.new,
        ArchiveMenuChecker.new(@file_system_accessor)
      ].map do |checker|
        checker.check(config_hash)
      end

      exceptions.compact.first
    end
  end
end
