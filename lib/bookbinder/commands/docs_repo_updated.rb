class Cli
  class DocReposUpdated < BookbinderCommand
    def run(_)
      workspace_dir = File.join('.')
      book = Book.new full_name: config.fetch('github_repo'), constituent_params: config.fetch('repos')
      change_monitor = DocRepoChangeMonitor.new book, workspace_dir
      change_monitor.build_necessary? ? 0 : 42
    end
  end
end