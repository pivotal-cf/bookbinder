require_relative 'git_hub_repository_cloner_facade'
require_relative 'local_filesystem_cloner_facade'

module Bookbinder
  module Ingest
    class ClonerFactory
      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
      end

      def produce(source, user_repo_dir)
        if user_repo_dir
          LocalFilesystemClonerFacade.new(logger, version_control_system, user_repo_dir)
        else
          GitHubRepositoryClonerFacade.new(logger, version_control_system)
        end
      end

      private

      attr_reader :logger, :version_control_system
    end
  end
end
