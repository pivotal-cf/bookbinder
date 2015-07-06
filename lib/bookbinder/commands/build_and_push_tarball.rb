require_relative '../deploy/archive'
require_relative '../ingest/destination_directory'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class BuildAndPushTarball < BookbinderCommand
      include Commands::Naming

      def usage
        [command_name,
         "Create a tarball from the final_app directory and push to the S3 bucket specified in your credentials.yml"]
      end

      def run(_)
        config = configuration_fetcher.fetch_config
        aws_credentials = configuration_fetcher.fetch_credentials[:aws]
        archive = Deploy::Archive.new(logger: @logger, key: aws_credentials.access_key, secret: aws_credentials.secret_key)
        archive.create_and_upload_tarball(
          build_number: ENV.fetch('BUILD_NUMBER', Time.now.strftime("%Y%m%d_%H%M")),
          bucket: aws_credentials.green_builds_bucket,
          namespace: Ingest::DestinationDirectory.new(config.book_repo)
        )
        0
      end
    end
  end
end
