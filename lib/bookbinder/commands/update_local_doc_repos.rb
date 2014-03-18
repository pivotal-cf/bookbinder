class Cli
  class UpdateLocalDocRepos < BookbinderCommand
    def run(_)
      config.repos.map { |conf| repo_for(conf) }.each(&:update_local_copy)
      0
    end

    def self.usage
      ''
    end

    private

    def repo_for(repo_config)
      local_repo_dir = File.absolute_path('../')
      Repository.new(full_name: repo_config['github_repo'],
                     local_repo_dir: local_repo_dir)
    end
  end
end
