class Cli

  include BookbinderLogger

  # TODO: test code in this file (we only test #run and the RunPublishCi command)

  def run(args)
    log 'No command supplied' and return if args.empty?
    command = args[0]
    command_arguments = args[1..-1]
    hash = {'publish' => Publish,
            'build_and_push_tarball' => BuildAndPushTarball,
            'doc_repos_updated' => DocReposUpdated,
            'push_local_to_staging' => PushLocalToStaging,
            'push_to_prod' => PushToProd,
            'run_publish_ci' => RunPublishCI,
            'update_local_doc_repos' => UpdateLocalDocRepos}
    if hash[command]
      hash[command].new.run command_arguments
    else
      log "Unrecognized command '#{command}'"
    end

  end

  class Publish
    def run(arguments)

      usage_message = 'usage: publish <local|github>'

      unless arguments.size == 1
        puts usage_message
        return 1
      end

      unless %w(local github).include?(arguments[0])
        puts usage_message
        return 1
      end

      local_repo_dir = (arguments[0] == 'local') ? File.absolute_path('../') : nil

      config = YAML.load File.read('./config.yml')

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
                                  github_username: config['github']['username'],
                                  github_password: config['github']['password'],
                                  pdf: pdf_hash

      success ? 0 : 1
    end
  end

  class BuildAndPushTarball
    def run(unused)
      config = YAML.load File.read('config.yml')

      build_number = ENV['BUILD_NUMBER']
      repository = GreenBuildRepository.new config['aws']['access_key'],
                                            config['aws']['secret_key']
      tarball_path = repository.create build_number, 'final_app', config['aws']['green_builds_bucket']
      FileUtils.cp tarball_path, 'output'
      0
    end
  end

  class DocReposUpdated
    def run(unused)
      config = YAML.load File.read('config.yml')

      workspace_dir = File.join('..')
      change_monitor = DocRepoChangeMonitor.new config['repos'],
                                                workspace_dir,
                                                config['github']['username'],
                                                config['github']['password']

      change_monitor.build_necessary? ? 0 : 42
    end
  end

  class PushLocalToStaging
    def run(unused)
      config = YAML.load File.read('config.yml')

      Pusher.new.push config['cloud_foundry']['api_endpoint'],
                      config['cloud_foundry']['organization'],
                      config['cloud_foundry']['staging_space'],
                      config['cloud_foundry']['app_name'],
                      './final_app',
                      config['cloud_foundry']['username'],
                      config['cloud_foundry']['password']
      0
    end
  end

  class PushToProd

    include BookbinderLogger

    def run(arguments)
      config = YAML.load File.read('config.yml')

      app_dir = Dir.mktmpdir
      repository = GreenBuildRepository.new config['aws']['access_key'],
                                            config['aws']['secret_key']
      repository.download app_dir, config['aws']['green_builds_bucket'], arguments[0]
      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow
      Pusher.new.push config['cloud_foundry']['api_endpoint'],
                      config['cloud_foundry']['organization'],
                      config['cloud_foundry']['production_space'],
                      config['cloud_foundry']['app_name'],
                      app_dir

      0
    end
  end

  class RunPublishCI
    def run(unused)
      if 0 == Publish.new.run(['github'])
        if 0 == PushLocalToStaging.new.run([])
          if 0 == BuildAndPushTarball.new.run([])
            return 0
          end
        end
      end
      1
    end
  end

  class UpdateLocalDocRepos
    def run(unused)
      config = YAML.load File.read('config.yml')
      local_repo_dir = File.absolute_path('../')
      LocalDocReposUpdater.new.update config['repos'], local_repo_dir
      0
    end
  end

end

