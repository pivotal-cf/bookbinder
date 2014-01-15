class Cli
  class RunPublishCI < BookbinderCommand
    def run(_)
      (
      (0 == Publish.new.run(['github'])) &&
          (0 == PushLocalToStaging.new.run([])) &&
          (0 == BuildAndPushTarball.new.run([]))
      ) ? 0 : 1
    end
  end
end