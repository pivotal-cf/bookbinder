
class Cli
  include BookbinderLogger

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
    'tag' => Tag
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
    log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
  end

  def run_command(command, command_arguments)
    configuration = config
    raise 'Non-unique directory names' unless configuration.valid?
    command.new(configuration).run command_arguments
  rescue Configuration::CredentialKeyError => e
    log "#{e.message}, in credentials.yml".red
    1
  rescue KeyError => e
    log "#{e.message}, in config.yml".red
    1
  rescue Cli::InvalidArguments
    log usage_message.command(command)
    1
  rescue => e
    log e.message.red
    1
  end

  def config
    @config ||= fetch_config
  end

  def fetch_config
    config_hash = YAML.load(File.read('./config.yml'))
    raise 'config.yml is empty' unless config_hash
    Configuration.new(config_hash)
  end

  def unrecognized_flag(name)
    log "Unrecognized flag '--#{name}'"
    usage_message.print
  end

  def unrecognized_command(name)
    log "Unrecognized command '#{name}'"
    usage_message.print
  end

  def usage_message
    UsageMessage.new(COMMAND_TO_CLASS_MAPPING, FLAGS)
  end
end
