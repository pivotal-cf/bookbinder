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

      def call(from: nil,
               ref: nil,
               parent_dir: nil,
               dir_name: nil)
        source = WorkingCopy.new(
          repo_dir: user_repo_dir,
          directory: dir_name,
          full_name: from
        )
        copied_to = copy!(
          source,
          Pathname(parent_dir).join(source.directory)
        )
        WorkingCopy.new(
          copied_to: copied_to,
          directory: dir_name,
          full_name: from,
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
          filesystem.copy(
            Pathname("#{source_copy.path}/."),
            dest_dir
          )
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
