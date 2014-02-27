class Cli
  class UpdateLocalDocRepos < BookbinderCommand
    def child_run(_)
      local_repo_dir = File.absolute_path('../')
      LocalDocReposUpdater.new.update config['repos'], local_repo_dir
      0
    end
  end
end
