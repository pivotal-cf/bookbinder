require_relative 'git_cloner'
require_relative 'local_filesystem_cloner'

module Bookbinder
  module Ingest
    class ClonerFactory
      def initialize(logger, filesystem, version_control_system)
        @logger = logger
        @filesystem = filesystem
        @version_control_system = version_control_system
      end

      def produce(source, user_repo_dir)
        if user_repo_dir
          LocalFilesystemCloner.new(logger, filesystem, user_repo_dir)
        else
          GitCloner.new(version_control_system)
        end
      end

      private

      attr_reader :logger, :filesystem, :version_control_system
    end
  end
end
