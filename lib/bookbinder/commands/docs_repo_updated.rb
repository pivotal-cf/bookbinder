class Cli
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
end