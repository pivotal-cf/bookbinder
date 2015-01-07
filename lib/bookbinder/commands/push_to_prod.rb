require_relative '../distributor'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushToProd < BookbinderCommand
      extend Commands::Naming

      def self.usage
        "push_to_prod [build_#] \t \t \t Push latest or <build_#> from your S3 bucket to the production host specified in credentials.yml"
      end

      def run(arguments)
        Distributor.build(@logger, options(arguments)).distribute
        0
      end

      private

      def options(arguments)
        {
          app_dir: Dir.mktmpdir,
          build_number: arguments[0],

          aws_credentials: config.aws_credentials,
          cf_credentials: config.cf_production_credentials,

          book_repo: config.book_repo,
          production: true
        }
      end
    end
  end
end
