class Cli
  class RunPublishCI < BookbinderCommand
    def run(_)
      check_params
      (
      (0 == Publish.new(config).run(['github'])) &&
          (0 == PushLocalToStaging.new(config).run([])) &&
          (0 == BuildAndPushTarball.new(config).run([]))
      ) ? 0 : 1
    end

    def self.usage
      ''
    end

    private

    def check_params
      raise BuildAndPushTarball::MissingBuildNumber unless ENV['BUILD_NUMBER']
      config.book_repo
    end
  end
end
