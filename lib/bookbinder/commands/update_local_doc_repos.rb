module Bookbinder
  class Cli
    class UpdateLocalDocRepos < BookbinderCommand
      def self.usage
        'update_local_doc_repos'
      end

      def run(_)
        config.sections.map { |conf| repo_for(conf) }.each(&:update_local_copy)
        0
      end

      private

      def repo_for(section_config)
        local_repo_dir = File.absolute_path('../')
        GitHubRepository.new(logger: @logger, full_name: section_config['repository']['name'],
                       local_repo_dir: local_repo_dir)
      end
    end
  end
end
