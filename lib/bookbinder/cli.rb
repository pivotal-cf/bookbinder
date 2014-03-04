class Cli
  include BookbinderLogger

  class CredentialKeyError < StandardError;
  end
  class InvalidArguments < StandardError;
  end

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

    if command
      run_command(command, command_arguments)
    else
      display_usage command_name
    end
  end

  private

  def run_command(command, command_arguments)
    command.new(config).run command_arguments
  rescue Cli::CredentialKeyError => e
    log "#{e.message}, in credentials.yml".red
    1
  rescue KeyError => e
    log "#{e.message}, in config.yml".red
    1
  rescue Cli::InvalidArguments
    log usage_message(command)
    1
  rescue => e
    log e.message.red
    1
  end

  def config
    return @config if @config

    config_hash = YAML.load(File.read('./config.yml'))
    raise 'config.yml is empty' unless config_hash
    @config = Configuration.new(config_hash)
  end

  def display_usage(name)
    log "Unrecognized command '#{name}'"
    log usage_header
    log usage_messages
  end

  def usage_messages
    COMMAND_TO_CLASS_MAPPING.values.map do |command_class|
      "  #{usage_message(command_class)}"
    end.sort
  end

  def usage_message(command_class)
    "bookbinder #{command_class.name.split('::').last.underscore} #{command_class.usage}"
  end

  def usage_header
    <<TEXT

Bookbinder documentation can be found at https://github.com/pivotal-cf/docs-bookbinder

Usage (preface with 'bundle exec ' when using rbenv):
TEXT
  end
end
