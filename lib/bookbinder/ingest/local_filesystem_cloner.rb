require_relative 'destination_directory'
require_relative 'working_copy'
require_relative 'missing_working_copy'

module Bookbinder
  module Ingest
    class LocalFilesystemCloner
      def initialize(streams, filesystem, user_repo_dir)
        @streams = streams
        @user_repo_dir = user_repo_dir
        @filesystem = filesystem
      end

      def call(source_repo_name: nil,
               source_ref: nil,
               destination_parent_dir: nil,
               destination_dir_name: nil)
        copy!(
          source_repo_name,
          Pathname(user_repo_dir).join(source_repo_name.split('/').last),
          Pathname(destination_parent_dir).join(DestinationDirectory.new(source_repo_name, destination_dir_name))
        )
      end

      private

      attr_reader :streams, :filesystem, :user_repo_dir

      def copy!(source_repo_name, source_dir, dest_dir)
        source_exists = filesystem.file_exist?(source_dir)

        if source_exists && filesystem.file_exist?(dest_dir)
          announce_copy(source_dir)
          WorkingCopy.new(
            copied_to: dest_dir,
            full_name: source_repo_name,
          )
        elsif source_exists
          announce_copy(source_dir)
          filesystem.copy_contents(source_dir, dest_dir)
          WorkingCopy.new(
            copied_to: dest_dir,
            full_name: source_repo_name,
          )
        else
          streams[:out].puts "  skipping (not found) #{source_dir}"
          MissingWorkingCopy.new(source_repo_name)
        end
      end

      def announce_copy(source_dir)
        streams[:out].puts "  copying #{source_dir}"
      end
    end
  end
end
