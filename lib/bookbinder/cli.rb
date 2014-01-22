class Cli

  include BookbinderLogger

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
    command = args[0]
    command_arguments = args[1..-1]

    if command_to_class_mapping[command]
      begin
        command_to_class_mapping[command].new.run command_arguments
      rescue KeyError => e
        # assumes that invalid fetches are into the config hash
        log "#{e.message}, in config.yml".red
      rescue => e
        log e.message.red
        1
      end
    else
      log "Unrecognized command '#{command}'"
      log <<TEXT

Bookbinder documentation can be found at https://github.com/pivotal-cf/docs-bookbinder

Usage (preface with 'bundle exec ' when using rbenv):
TEXT
      log usage_messages
    end
  end

  def usage_messages
    command_to_class_mapping.values.map do |command_class|
      "  #{command_class.new.usage_message}"
    end.sort
  end
end

