class Cli
  class BuildAndPushTarball < BookbinderCommand
    def run(_)
      repository = GreenBuildRepository.new key: config['aws']['access_key'],
                                            secret: config['aws']['secret_key']

      repository.create build_number: ENV['BUILD_NUMBER'], bucket: config['aws']['green_builds_bucket']
      0
    end
  end
end
