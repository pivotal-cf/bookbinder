require_relative 'naming'

module Bookbinder
  module Commands
    class Version
      include Commands::Naming

      def initialize(logger)
        @logger = logger
      end

      def command_name
        '--version'
      end

      def usage
        "--version \t \t \t \t Print the version of bookbinder"
      end

      def run(*)
        root = File.expand_path('../../../../', __FILE__)
        @logger.log "bookbinder #{Gem::Specification::load(File.join root, "bookbinder.gemspec").version}"
        0
      end

    end
  end
end
