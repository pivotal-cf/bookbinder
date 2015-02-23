require_relative 'app_fetcher'
require_relative 'artifact_namer'

module Bookbinder
  class Distributor
    EXPIRATION_HOURS = 2

    def self.build(logger, options)
      namespace = GitHubRepository.new(logger: logger, full_name: options[:book_repo], git_accessor: Git).short_name
      namer = ArtifactNamer.new(namespace, options[:build_number], 'log', '/tmp')

      archive = Archive.new(logger: logger, key: options[:aws_credentials].access_key, secret: options[:aws_credentials].secret_key)
      cf_command_runner = CfCommandRunner.new(logger, options[:cf_credentials], namer.full_path)
      cf_app_fetcher = AppFetcher.new(options[:cf_credentials].flat_routes, cf_command_runner)

      pusher = Pusher.new(cf_command_runner, cf_app_fetcher)
      new(logger, archive, pusher, namespace, namer, options)
    end

    def initialize(logger, archive, pusher, namespace, namer, options)
      @logger = logger
      @archive = archive
      @pusher = pusher
      @namespace = namespace
      @namer = namer
      @options = options
    end

    def distribute
      begin
        download if cf_credentials.download_archive_before_push?
        push_app
        nil
      rescue => e
        cf_space = options[:production] ? cf_credentials.production_space : cf_credentials.staging_space
        cf_routes = options[:production] ? cf_credentials.production_host : cf_credentials.staging_host
        @logger.error "[ERROR] #{e.message}\n[DEBUG INFO]\nCF organization: #{cf_credentials.organization}\nCF space: #{cf_space}\nCF account: #{cf_credentials.username}\nroutes: #{cf_routes}"
      ensure
        upload_trace
      end
    end

    private

    attr_reader :options, :archive, :namer, :namespace, :pusher

    def download
      archive.download(download_dir: options[:app_dir], bucket: options[:aws_credentials].green_builds_bucket, build_number: options[:build_number],
                       namespace: namespace)
    end

    def push_app
      warn if options[:production]
      pusher.push(options[:app_dir])
    end

    def upload_trace
      uploaded_file = archive.upload_file(options[:aws_credentials].green_builds_bucket, namer.filename, namer.full_path)
      @logger.log("Your cf trace file is available at: #{uploaded_file.url(Time.now.to_i + EXPIRATION_HOURS*60*60).green}")
      @logger.log("This URL will expire in #{EXPIRATION_HOURS} hours, so if you need to share it, make sure to save a copy now.")
    rescue Errno::ENOENT
      @logger.error "Could not find CF trace file: #{namer.full_path}"
    end

    def warn
      @logger.warn 'Warning: You are pushing to CF Docs production. Be careful.'
    end

    def cf_credentials
      options[:cf_credentials]
    end
  end
end
