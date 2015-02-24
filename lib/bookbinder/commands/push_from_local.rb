require_relative '../distributor'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushFromLocal < BookbinderCommand
      include Commands::Naming

      def usage
        [command_name,
         "Push the contents of final_app to the staging host specified in credentials.yml"]
      end

      def run(_)
        Distributor.build(@logger, options).distribute
        0
      end

      private

      def command_name
        'push_local_to_staging'
      end

      def options
        {
            app_dir: './final_app',
            build_number: ENV['BUILD_NUMBER'],

            aws_credentials: config.aws_credentials,
            cf_credentials: config.cf_credentials('staging'),

            book_repo: config.book_repo,
        }
      end
    end
  end
end
