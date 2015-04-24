module Bookbinder
  module Ingest
    class GitHubRepositoryCloner
      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
      end

      def call(from: nil,
               ref: nil,
               parent_dir: nil,
               dir_name: nil)
        repo = GitHubRepository.
          build_from_remote(logger,
                            {'repository' => {'name' => from},
                             'directory' => dir_name},
                             version_control_system).
                             tap { |repo| repo.copy_from_remote(parent_dir, ref) }
        WorkingCopy.new(
          copied_to: repo.copied_to,
          directory: dir_name,
          full_name: from,
        )
      end

      private

      attr_reader :logger, :version_control_system
    end
  end
end
