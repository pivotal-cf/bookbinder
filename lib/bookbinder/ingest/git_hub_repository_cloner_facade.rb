module Bookbinder
  module Ingest
    class GitHubRepositoryClonerFacade
      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
      end

      def call(from: nil,
               ref: nil,
               parent_dir: nil,
               dir_name: nil)
        GitHubRepository.
          build_from_remote(logger,
                            {'repository' => {'name' => from},
                             'directory' => dir_name},
                             version_control_system).
                             tap { |repo| repo.copy_from_remote(parent_dir, ref) }
      end

      private

      attr_reader :logger, :version_control_system
    end
  end
end
