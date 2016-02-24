require_relative 'checkers/duplicate_section_name_checker'
require_relative 'checkers/archive_menu_checker'
require_relative 'checkers/required_keys_checker'
require_relative 'checkers/repository_name_presence_checker'
require_relative 'checkers/ditamap_presence_checker'
require_relative 'checkers/section_presence_checker'
require_relative 'checkers/products_checker'

module Bookbinder
  module Config
    class Validator
      def initialize(file_system_accessor)
        @file_system_accessor = file_system_accessor
      end

      def exceptions(config)
        exceptions = [
          Checkers::RequiredKeysChecker.new,
          Checkers::DuplicateSectionNameChecker.new,
          Checkers::RepositoryNamePresenceChecker.new,
          Checkers::SectionPresenceChecker.new,
          Checkers::DitamapPresenceChecker.new,
          Checkers::ArchiveMenuChecker.new(@file_system_accessor),
          Checkers::ProductsChecker.new
        ].map do |checker|
          checker.check(config)
        end

        exceptions.compact
      end
    end
  end
end
