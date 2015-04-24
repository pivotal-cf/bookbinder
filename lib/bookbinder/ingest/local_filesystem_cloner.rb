require_relative 'working_copy'

module Bookbinder
  module Ingest
    class LocalFilesystemCloner
      def initialize(logger, version_control_system, user_repo_dir)
        @logger = logger
        @version_control_system = version_control_system
        @user_repo_dir = user_repo_dir
      end

      def call(from: nil,
               ref: nil,
               parent_dir: nil,
               dir_name: nil)
        repo = GitHubRepository.
          build_from_local(logger,
                           {'repository' => {'name' => from},
                            'directory' => dir_name},
                            user_repo_dir,
                            version_control_system).
                            tap { |repo| repo.copy_from_local(parent_dir) }
        WorkingCopy.new(
          copied: repo.copied?,
          copied_to: repo.copied_to,
          directory: dir_name,
          full_name: from,
        )
      end

      private

      attr_reader :logger, :version_control_system, :user_repo_dir
    end
  end
end
