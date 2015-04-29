require_relative '../deprecated_logger'
require_relative 'working_copy'

module Bookbinder
  module Ingest
    class LocalFilesystemCloner
      def initialize(logger, filesystem, user_repo_dir)
        @logger = logger
        @user_repo_dir = user_repo_dir
        @filesystem = filesystem
      end

      def call(source_repo_name: nil,
               source_ref: nil,
               destination_parent_dir: nil,
               destination_dir_name: nil)
        copied_to = copy!(
          WorkingCopy.new(repo_dir: user_repo_dir, full_name: source_repo_name),
          Pathname(destination_parent_dir).join(DestinationDirectory.new(source_repo_name, destination_dir_name))
        )
        WorkingCopy.new(
          copied_to: copied_to,
          directory: destination_dir_name,
          full_name: source_repo_name,
        )
      end

      private

      attr_reader :logger, :filesystem, :user_repo_dir

      def copy!(source_copy, dest_dir)
        source_exists = filesystem.file_exist?(source_copy.path)

        if source_exists && filesystem.file_exist?(dest_dir)
          announce_copy(source_copy)
          dest_dir
        elsif source_exists
          announce_copy(source_copy)
          filesystem.copy_contents(source_copy.path, dest_dir)
          dest_dir
        else
          logger.log '  skipping (not found) '.magenta + source_copy.path.to_s
        end
      end

      def announce_copy(source_copy)
        logger.log '  copying '.yellow + source_copy.path.to_s
      end
    end
  end
end
