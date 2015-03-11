require_relative 'git_hub_repository_cloner'
require_relative 'local_filesystem_cloner'

module Bookbinder
  module Ingest
    class ClonerFactory
      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
      end

      def produce(source, user_repo_dir)
        if user_repo_dir
          LocalFilesystemCloner.new(logger, version_control_system, user_repo_dir)
        else
          GitHubRepositoryCloner.new(logger, version_control_system)
        end
      end

      private

      attr_reader :logger, :version_control_system
    end
  end
end
