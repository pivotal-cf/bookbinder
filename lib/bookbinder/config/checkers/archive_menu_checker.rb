module Bookbinder
  module Config
    module Checkers
      class ArchiveMenuChecker
        MissingArchiveMenuPartialError = Class.new(RuntimeError)
        ArchiveMenuNotDefinedError = Class.new(RuntimeError)
        EmptyArchiveItemsError = Class.new(RuntimeError)

        def initialize(file_system_accessor)
          @file_system_accessor = file_system_accessor
        end

        def check(config)
          partial_location = './master_middleman/source/archive_menus/_default.erb'
          if config.archive_menu && config.archive_menu.include?(nil)
            EmptyArchiveItemsError.new 'Did you forget to add a value to the archive_menu?'
          elsif config.archive_menu && !file_system_accessor.file_exist?(partial_location)
            MissingArchiveMenuPartialError.new "You must provide a template partial named at #{partial_location}"
          end
        end

        private

        attr_reader :file_system_accessor

      end
    end
  end
end
