require 'git'
require_relative '../directory_helpers'
require_relative '../local_filesystem_accessor'
require_relative 'update_failure'
require_relative 'update_success'

module Bookbinder
  module Ingest
    class GitAccessor
      TagExists = Class.new(RuntimeError)
      InvalidTagRef = Class.new(RuntimeError)
      include DirectoryHelperMethods

      def clone(url, name, path: nil, checkout: 'master')
        cached_clone(url, name, Pathname(path)).tap do |git|
          git.checkout(checkout)
        end
      end

      def update(cloned_path)
        Git.open(cloned_path).pull
        Ingest::UpdateSuccess.new
      rescue ArgumentError, Git::GitExecuteError => e
        case e.message
        when /overwritten by merge/
          Ingest::UpdateFailure.new('merge error')
        when /path does not exist/
          Ingest::UpdateFailure.new('not found')
        else
          raise
        end
      end

      def read_file(filename, from_repo: nil, checkout: 'master')
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          git = cached_clone(from_repo, temp_name("read-file"), path)
          git.checkout(checkout)
          path.join(temp_name("read-file"), filename).read
        end
      end

      def remote_tag(url, tagname, commit_or_object)
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          git = cached_clone(url, temp_name("tag"), path)
          git.config('user.name', 'Bookbinder')
          git.config('user.email', 'bookbinder@cloudfoundry.org')
          begin
            git.add_tag(tagname, "origin/#{commit_or_object}",
              message: 'Tagged by Bookbinder')
          rescue Git::GitExecuteError => e
            case e.message
              when /already exists/
                raise TagExists
              when /as a valid ref/
                raise InvalidTagRef
              else
                raise
            end
          end
          git.push("origin", "master", tags: true)
        end
      end

      def author_date(path, exclusion_flag: '[exclude]', dita: false)
        fs = LocalFilesystemAccessor.new

        if dita
          source_dir = 'preprocessing'
          path_to_file = path.sub(/\.html(.md)?(.erb)?/, '.xml')
        else
          source_dir = source_dir_name
          path_to_file = path
        end


        Pathname(path).dirname.ascend do |current_dir|
          if (
              current_dir.to_s.include?(source_dir) &&
              current_dir.entries.include?(Pathname(".git")) &&
              fs.source_file_exists?(Pathname(path).dirname, path_to_file)
            )

            git = Git.open(current_dir)
            logs = git.gblob(path_to_file).log

            last_non_excluded_commit = logs.detect { |log| !log.message.include?(exclusion_flag) }

            return last_non_excluded_commit.author.date if last_non_excluded_commit
          end
        end
      end

      private

      def temp_name(purpose)
        "bookbinder-git-accessor-#{purpose}"
      end

      def cached_clone(url, name, path)
        dest_dir = path.join(name)
        if dest_dir.exist?
          Git.open(dest_dir)
        else
          Git.clone(url, name, path: path, recursive: true)
        end
      end
    end
  end
end
