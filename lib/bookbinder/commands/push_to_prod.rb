class Cli
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
end