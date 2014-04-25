
class Cli
  class InvalidArguments < StandardError;
  end

  FLAGS = %w(version)

  # breaking this command => class naming convention will break usage_messages!
  COMMAND_TO_CLASS_MAPPING = {
    'publish' => Publish,
    'build_and_push_tarball' => BuildAndPushTarball,
    'doc_repos_updated' => DocReposUpdated,
    'push_local_to_staging' => PushLocalToStaging,
    'push_to_prod' => PushToProd,
    'run_publish_ci' => RunPublishCI,
    'update_local_doc_repos' => UpdateLocalDocRepos,
    'tag' => Tag,
    'generate_pdf' => GeneratePDF
  }.freeze

  def run(args)
    command_name = args[0]
    command = COMMAND_TO_CLASS_MAPPING[command_name]
    command_arguments = args[1..-1]

    if command_name && command_name.match(/^--/)
      flag = command_name[2..-1]
      if FLAGS.include? flag
        self.send flag
      else
        unrecognized_flag(flag)
      end
      0
    elsif command
      run_command(command, command_arguments)
    else
      unrecognized_command command_name
    end
  end

  private

  def version
    logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
  end

  def run_command(command, command_arguments)
    configuration = config
    raise 'Non-unique directory names' unless configuration.valid?
    command.new(logger, configuration).run command_arguments
  rescue Configuration::CredentialKeyError => e
    logger.error "#{e.message}, in credentials.yml"
    1
  rescue KeyError => e
    logger.error "#{e.message} from your configuration."
    1
  rescue Cli::InvalidArguments
    logger.log usage_message.command(command)
    1
  rescue => e
    logger.error e.message
    1
  end

  def config
    @config ||= fetch_config
  end

  def fetch_config
    config_hash              = YAML.load(File.read('./config.yml'))
    if config_hash
      if File.exists?('./pdf_index.yml')
        config_hash['pdf_index'] = YAML.load(File.read('./pdf_index.yml'))
      else
        config_hash['pdf_index'] = nil
      end
    end
    raise 'config.yml is empty' unless config_hash
    Configuration.new(logger, config_hash)
  end

  def unrecognized_flag(name)
    logger.log "Unrecognized flag '--#{name}'"
    usage_message.print
  end

  def unrecognized_command(name)
    logger.log "Unrecognized command '#{name}'"
    usage_message.print
  end

  def usage_message
    UsageMessage.new(logger, COMMAND_TO_CLASS_MAPPING, FLAGS)
  end

  def logger
    @logger ||= BookbinderLogger.new
  end
end
