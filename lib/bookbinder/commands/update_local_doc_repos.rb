class Cli
  class UpdateLocalDocRepos < BookbinderCommand
    def run(_)
      local_repo_dir = File.absolute_path('../')
      LocalDocReposUpdater.new.update(config.repos, local_repo_dir)
      0
    end

    def self.usage
      ''
    end
  end
end
