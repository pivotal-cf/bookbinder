module Bookbinder
  module Commands
    class Version < BookbinderCommand
      def self.to_s
        "version"
      end

      def self.command_name
        '--version'
      end

      def run(*)
        logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
        0
      end

      private

      attr_reader :logger
    end
  end
end
