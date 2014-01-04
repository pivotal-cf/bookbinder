class Cli

  include BookbinderLogger

  def command_to_class_mapping
    {'publish' => Publish,
     'build_and_push_tarball' => BuildAndPushTarball,
     'doc_repos_updated' => DocReposUpdated,
     'push_local_to_staging' => PushLocalToStaging,
     'push_to_prod' => PushToProd,
     'run_publish_ci' => RunPublishCI,
     'update_local_doc_repos' => UpdateLocalDocRepos}
    # breaking this command => class naming convention will break usage_messages!
  end

  def run(args)
    command = args[0]
    command_arguments = args[1..-1]

    if command_to_class_mapping[command]
      begin
        command_to_class_mapping[command].new.run command_arguments
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

  class BookbinderCommand

    include BookbinderLogger

    def config
      @config ||= YAML.load(File.read('./config.yml'))
    end

    def usage_message
      "bookbinder #{self.class.name.split('::').last.underscore} #{usage}"
    end

    def usage
      ""
    end
  end

  class Publish < BookbinderCommand
    def run(arguments)
      unless %w(local github).include?(arguments[0]) &&
          (arguments[1] == nil || arguments[1] == '--verbose')
        puts "usage: #{usage_message}"
        return 1
      end

      local_repo_dir = (arguments[0] == 'local') ? File.absolute_path('../') : nil

      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'],
                                  filename: config['pdf']['filename'],
                                  header: config['pdf']['header']}
      : nil

      publisher = Publisher.new
      success = publisher.publish repos: config['repos'],
                                  output_dir: File.absolute_path('output'),
                                  master_middleman_dir: File.absolute_path('master_middleman'),
                                  local_repo_dir: local_repo_dir,
                                  final_app_dir: File.absolute_path('final_app'),
                                  host_for_sitemap: config['cloud_foundry']['public_host'],
                                  github_username: config['github']['username'],
                                  github_password: config['github']['password'],
                                  pdf: pdf_hash,
                                  template_variables: config['template_variables'],
                                  verbose: arguments[1] == '--verbose'

      success ? 0 : 1
    end

    def usage
      "<local|github> [--verbose]"
    end
  end

  class BuildAndPushTarball < BookbinderCommand
    def run(_)
      build_number = ENV['BUILD_NUMBER']
      repository = GreenBuildRepository.new config['aws']['access_key'],
                                            config['aws']['secret_key']
      repository.create build_number, 'final_app', config['aws']['green_builds_bucket']
      0
    end
  end

  class DocReposUpdated < BookbinderCommand
    def run(_)
      workspace_dir = File.join('.')
      change_monitor = DocRepoChangeMonitor.new config['repos'],
                                                workspace_dir,
                                                config['github']['username'],
                                                config['github']['password']

      change_monitor.build_necessary? ? 0 : 42
    end
  end

  class PushLocalToStaging < BookbinderCommand
    def run(_)
      Pusher.new.push config['cloud_foundry']['api_endpoint'],
                      config['cloud_foundry']['staging_host'],
                      config['cloud_foundry']['organization'],
                      config['cloud_foundry']['staging_space'],
                      config['cloud_foundry']['app_name'],
                      './final_app',
                      config['cloud_foundry']['username'],
                      config['cloud_foundry']['password']
      0
    end
  end

  class PushToProd < BookbinderCommand
    def run(arguments)
      app_dir = Dir.mktmpdir
      repository = GreenBuildRepository.new config['aws']['access_key'],
                                            config['aws']['secret_key']
      repository.download app_dir, config['aws']['green_builds_bucket'], arguments[0]
      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow
      Pusher.new.push config['cloud_foundry']['api_endpoint'],
                      config['cloud_foundry']['production_host'],
                      config['cloud_foundry']['organization'],
                      config['cloud_foundry']['production_space'],
                      config['cloud_foundry']['app_name'],
                      app_dir

      0
    end

    def usage
      "[build_#]"
    end
  end

  class RunPublishCI < BookbinderCommand
    def run(_)
      (
      (0 == Publish.new.run(['github'])) &&
          (0 == PushLocalToStaging.new.run([])) &&
          (0 == BuildAndPushTarball.new.run([]))
      ) ? 0 : 1
    end
  end

  class UpdateLocalDocRepos < BookbinderCommand
    def run(_)
      local_repo_dir = File.absolute_path('../')
      LocalDocReposUpdater.new.update config['repos'], local_repo_dir
      0
    end
  end

end

