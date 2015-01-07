require_relative 'bookbinder_command'

module Bookbinder
  module Commands
    class Version < BookbinderCommand
      def self.to_s
        'version'
      end

      def self.command_name
        '--version'
      end

      def self.usage
        "--version \t \t \t \t Print the version of bookbinder"
      end

      def run(*)
        @logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
        0
      end

    end
  end
end
