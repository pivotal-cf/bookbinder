require_relative 'destination_directory'
require_relative 'repo_identifier'
require_relative 'working_copy'

module Bookbinder
  module Ingest
    class GitCloner
      def initialize(version_control_system)
        @version_control_system = version_control_system
      end

      def call(source_repo_name: nil,
               source_ref: "master",
               destination_parent_dir: nil,
               destination_dir_name: nil)
        dest_dir = DestinationDirectory.new(source_repo_name, destination_dir_name)
        copied_to = Pathname(destination_parent_dir).join(dest_dir)
        version_control_system.clone(
          RepoIdentifier.new(source_repo_name),
          dest_dir,
          path: destination_parent_dir,
          checkout: source_ref
        )
        WorkingCopy.new(
          copied_to: copied_to,
          full_name: source_repo_name,
          ref: source_ref
        )
      end

      private

      attr_reader :version_control_system
    end
  end
end
