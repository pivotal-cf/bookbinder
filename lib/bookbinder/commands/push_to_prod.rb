module Bookbinder
  class Cli
    class PushToProd < BookbinderCommand
      def run(arguments)
        Distributor.build(@logger, options(arguments)).distribute
        0
      end

      def self.usage
        '[build_#]'
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