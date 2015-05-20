require_relative 'validation_checkers/duplicate_section_name_checker'
require_relative 'validation_checkers/archive_menu_checker'
require_relative 'validation_checkers/required_keys_checker'
require_relative 'validation_checkers/repository_name_presence_checker'
require_relative 'validation_checkers/dita_section_checker'

module Bookbinder
  class ConfigurationValidator
    def initialize(logger, file_system_accessor)
      @logger = logger
      @file_system_accessor = file_system_accessor
    end

    def exceptions(config_hash)
      exceptions = [
        RequiredKeysChecker.new,
        DuplicateSectionNameChecker.new,
        RepositoryNamePresenceChecker.new,
        DitaSectionChecker.new,
        ArchiveMenuChecker.new(@file_system_accessor)
      ].map do |checker|
        checker.check(config_hash)
      end

      exceptions.compact
    end
  end
end
