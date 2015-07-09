require_relative '../cf_command_runner'
require_relative '../ingest/destination_directory'
require_relative '../sheller'
require_relative 'app_fetcher'
require_relative 'archive'
require_relative 'artifact'
require_relative 'pusher'

module Bookbinder
  module Deploy
    class Distributor
      EXPIRATION_HOURS = 2

      def self.build(streams, archive, deployment)
        cf_command_runner = CfCommandRunner.new(streams, Sheller.new, deployment.cf_credentials, deployment.artifact_full_path)
        cf_app_fetcher = AppFetcher.new(deployment.flat_routes, cf_command_runner)
        pusher = Pusher.new(cf_command_runner, cf_app_fetcher)
        new(streams, archive, pusher, deployment)
      end

      def initialize(streams, archive, pusher, deployment)
        @streams = streams
        @archive = archive
        @pusher = pusher
        @deployment = deployment
      end

      def distribute
        push_app
        nil
      rescue => e
        streams[:err].puts(<<-ERROR.chomp)
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

      attr_reader :archive, :deployment, :pusher, :streams

      def push_app
        pusher.push(deployment.app_dir)
      end

      def upload_trace
        uploaded_file = archive.upload_file(deployment.green_builds_bucket, deployment.artifact_filename, deployment.artifact_full_path)
        streams[:success].puts("Your cf trace file is available at: #{uploaded_file.url(Time.now.to_i + EXPIRATION_HOURS*60*60)}")
        streams[:success].puts("This URL will expire in #{EXPIRATION_HOURS} hours, so if you need to share it, make sure to save a copy now.")
      rescue Errno::ENOENT
        streams[:err].puts("Could not find CF trace file: #{deployment.artifact_full_path}")
      end

      def cf_credentials
        deployment.cf_credentials
      end
    end
  end
end
