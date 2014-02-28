class Cli
  include BookbinderLogger

  class CredentialKeyError < StandardError; end

  def command_to_class_mapping
    {'publish' => Publish,
     'build_and_push_tarball' => BuildAndPushTarball,
     'doc_repos_updated' => DocReposUpdated,
     'push_local_to_staging' => PushLocalToStaging,
     'push_to_prod' => PushToProd,
     'run_publish_ci' => RunPublishCI,
     'update_local_doc_repos' => UpdateLocalDocRepos,
     'tag' => Tag}
    # breaking this command => class naming convention will break usage_messages!
  end

  def run(args)
    command_name      = args[0]
    command           = command_to_class_mapping[command_name]
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
  rescue => e
    log e.message.red
    1
  end

  def config
    @config ||= YAML.load(File.read('./config.yml'))
    raise 'config.yml is empty' unless @config
    @config.merge(credentials)
  end

  def credentials
    return {} unless @config['cred_repo']
    @credentials ||= CredRepo.new(full_name: @config['cred_repo']).credentials
  end

  def display_usage(name)
    log "Unrecognized command '#{name}'"
    log usage_header
    log usage_messages
  end

  def usage_messages
    command_to_class_mapping.values.map do |command_class|
      "  #{command_class.usage_message}"
    end.sort
  end

  def usage_header
    <<TEXT

Bookbinder documentation can be found at https://github.com/pivotal-cf/docs-bookbinder

Usage (preface with 'bundle exec ' when using rbenv):
TEXT
  end
end
