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
          Pathname(user_repo_dir).join(source_repo_name.split('/').last),
          Pathname(destination_parent_dir).join(DestinationDirectory.new(source_repo_name, destination_dir_name))
        )
        WorkingCopy.new(
          copied_to: copied_to,
          full_name: source_repo_name,
        )
      end

      private

      attr_reader :logger, :filesystem, :user_repo_dir

      def copy!(source_dir, dest_dir)
        source_exists = filesystem.file_exist?(source_dir)

        if source_exists && filesystem.file_exist?(dest_dir)
          announce_copy(source_dir)
          dest_dir
        elsif source_exists
          announce_copy(source_dir)
          filesystem.copy_contents(source_dir, dest_dir)
          dest_dir
        else
          logger.log '  skipping (not found) '.magenta + source_dir.to_s
        end
      end

      def announce_copy(source_dir)
        logger.log '  copying '.yellow + source_dir.to_s
      end
    end
  end
end
