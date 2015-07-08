require_relative '../cf_command_runner'
require_relative '../ingest/destination_directory'
require_relative '../sheller'
require_relative 'app_fetcher'
require_relative 'archive'
require_relative 'artifact'
require_relative 'deployment'
require_relative 'pusher'

module Bookbinder
  module Deploy
    class Distributor
      EXPIRATION_HOURS = 2

      def self.build(logger, options)
        deployment = Deployment.new(options)

        archive = Archive.new(
          logger: logger,
          key: deployment.aws_access_key,
          secret: deployment.aws_secret_key
        )
        cf_command_runner = CfCommandRunner.new(logger, Sheller.new, deployment.cf_credentials, deployment.artifact_full_path)
        cf_app_fetcher = AppFetcher.new(deployment.flat_routes, cf_command_runner)

        pusher = Pusher.new(cf_command_runner, cf_app_fetcher)
        new(logger, archive, pusher, deployment)
      end

      def initialize(logger, archive, pusher, deployment)
        @logger = logger
        @archive = archive
        @pusher = pusher
        @deployment = deployment
      end

      def distribute
        download if cf_credentials.download_archive_before_push?
        push_app
        nil
      rescue => e
        @logger.error(<<-ERROR.chomp)
  [ERROR] #{e.message}
  [DEBUG INFO]
  CF organization: #{cf_credentials.organization}
  CF space: #{cf_credentials.space}
  CF account: #{cf_credentials.username}
  routes: #{cf_credentials.routes}
        ERROR
        raise
      ensure
        upload_trace
      end

      private

      attr_reader :archive, :deployment, :pusher

      def download
        archive.download(download_dir: deployment.app_dir,
                         bucket: deployment.green_builds_bucket,
                         build_number: deployment.build_number,
                         namespace: deployment.namespace)
      end

      def push_app
        pusher.push(deployment.app_dir)
      end

      def upload_trace
        uploaded_file = archive.upload_file(deployment.green_builds_bucket, deployment.artifact_filename, deployment.artifact_full_path)
        @logger.log("Your cf trace file is available at: #{uploaded_file.url(Time.now.to_i + EXPIRATION_HOURS*60*60).green}")
        @logger.log("This URL will expire in #{EXPIRATION_HOURS} hours, so if you need to share it, make sure to save a copy now.")
      rescue Errno::ENOENT
        @logger.error "Could not find CF trace file: #{deployment.artifact_full_path}"
      end

      def cf_credentials
        deployment.cf_credentials
      end
    end
  end
end
