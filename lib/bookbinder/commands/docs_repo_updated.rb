class Cli
  class DocReposUpdated < BookbinderCommand
    def run(_)
      workspace_dir = File.join('.')
      change_monitor = DocRepoChangeMonitor.new config.fetch('repos'), workspace_dir
      change_monitor.build_necessary? ? 0 : 42
    end
  end
end