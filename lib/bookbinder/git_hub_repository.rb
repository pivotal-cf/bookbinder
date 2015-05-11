require_relative 'deprecated_logger'
require_relative 'git_client'
require_relative 'ingest/destination_directory'

module Bookbinder
  class GitHubRepository
    attr_reader :full_name, :copied_to

    def initialize(logger: nil,
                   full_name: nil,
                   github_token: nil,
                   local_repo_dir: nil)
      @logger = logger
      raise 'No full_name provided ' unless full_name
      @full_name = full_name
      @local_repo_dir = local_repo_dir

      @github = GitClient.new(access_token: github_token || ENV['GITHUB_API_TOKEN'])
    end

    def update_local_copy
      if File.exist?(path_to_local_repo)
        @logger.log 'Updating ' + path_to_local_repo.cyan
        Kernel.system("cd #{path_to_local_repo} && git pull")
      else
        announce_skip
      end
    end

    private

    def announce_skip
      @logger.log '  skipping (not found) '.magenta + path_to_local_repo
    end

    def head_sha
      @head_sha ||= @github.head_sha(full_name)
    end

    def path_to_local_repo
      if @local_repo_dir
        File.join(@local_repo_dir, Ingest::DestinationDirectory.new(full_name))
      end
    end

    def tags
      @github.tags @full_name
    end
  end
end
