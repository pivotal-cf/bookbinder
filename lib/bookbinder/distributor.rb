class Distributor
  include BookbinderLogger

  def self.build(options)
    namespace = Book.new(full_name: options[:book_repo]).short_name
    namer = ArtifactNamer.new(namespace, options[:build_number], 'log', '/tmp')

    archive = Archive.new(key: options[:aws_credentials].access_key, secret: options[:aws_credentials].secret_key)
    command_runner = CfCommandRunner.new(options[:cf_credentials], namer.full_path)
    pusher = Pusher.new(command_runner)
    new(archive, pusher, namespace, namer, options)
  end

  def initialize(archive, pusher, namespace, namer, options)
    @archive = archive
    @pusher = pusher
    @namespace = namespace
    @namer = namer
    @options = options
  end

  def distribute
    download if options[:production]
    push_app
    upload_trace
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
    archive.upload_file(options[:aws_credentials].green_builds_bucket, namer.filename, namer.full_path)
  end

  def warn
    log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow
  end
end
