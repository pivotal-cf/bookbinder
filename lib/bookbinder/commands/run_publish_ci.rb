class Cli
  class RunPublishCI < BookbinderCommand
    def run(_)
      raise 'You must set $BUILD_NUMBER to push an identifiable build.' unless ENV['BUILD_NUMBER']
      (
      (0 == Publish.new.run(['github'])) &&
          (0 == PushLocalToStaging.new.run([])) &&
          (0 == BuildAndPushTarball.new.run([]))
      ) ? 0 : 1
    end
  end
end