require_relative 'git_cloner'
require_relative 'local_filesystem_cloner'

module Bookbinder
  module Ingest
    class ClonerFactory
      def initialize(streams, filesystem, version_control_system)
        @streams = streams
        @filesystem = filesystem
        @version_control_system = version_control_system
      end

      def produce(user_repo_dir)
        if user_repo_dir
          LocalFilesystemCloner.new(streams, filesystem, user_repo_dir)
        else
          GitCloner.new(version_control_system)
        end
      end

      private

      attr_reader :streams, :filesystem, :version_control_system
    end
  end
end
