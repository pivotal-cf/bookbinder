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

      def self.build(logger, options)
        namespace = Ingest::DestinationDirectory.new(options[:book_repo])
        artifact = Artifact.new(namespace, options[:build_number], 'log', '/tmp')

        archive = Archive.new(logger: logger, key: options[:aws_credentials].access_key, secret: options[:aws_credentials].secret_key)
        cf_command_runner = CfCommandRunner.new(logger, Sheller.new, options[:cf_credentials], artifact.full_path)
        cf_app_fetcher = AppFetcher.new(options[:cf_credentials].flat_routes, cf_command_runner)

        pusher = Pusher.new(cf_command_runner, cf_app_fetcher)
        new(logger, archive, pusher, namespace, artifact, options)
      end

      def initialize(logger, archive, pusher, namespace, artifact, options)
        @logger = logger
        @archive = archive
        @pusher = pusher
        @namespace = namespace
        @artifact = artifact
        @options = options
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

      attr_reader :options, :archive, :artifact, :namespace, :pusher

      def download
        archive.download(download_dir: options[:app_dir],
                         bucket: options[:aws_credentials].green_builds_bucket,
                         build_number: options[:build_number],
                         namespace: namespace)
      end

      def push_app
        pusher.push(options[:app_dir])
      end

      def upload_trace
        uploaded_file = archive.upload_file(options[:aws_credentials].green_builds_bucket, artifact.filename, artifact.full_path)
        @logger.log("Your cf trace file is available at: #{uploaded_file.url(Time.now.to_i + EXPIRATION_HOURS*60*60).green}")
        @logger.log("This URL will expire in #{EXPIRATION_HOURS} hours, so if you need to share it, make sure to save a copy now.")
      rescue Errno::ENOENT
        @logger.error "Could not find CF trace file: #{artifact.full_path}"
      end

      def cf_credentials
        options[:cf_credentials]
      end
    end
  end
end
