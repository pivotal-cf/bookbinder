class Cli
  class BuildAndPushTarball < BookbinderCommand
    def run(_)
      build_number = ENV['BUILD_NUMBER']
      repository = GreenBuildRepository.new config['aws']['access_key'],
                                            config['aws']['secret_key']
      repository.create build_number, 'final_app', config['aws']['green_builds_bucket']
      0
    end
  end
end
