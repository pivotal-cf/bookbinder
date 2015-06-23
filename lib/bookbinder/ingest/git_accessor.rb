require 'git'
require_relative 'update_failure'
require_relative 'update_success'

module Bookbinder
  module Ingest
    class GitAccessor
      TagExists = Class.new(RuntimeError)
      InvalidTagRef = Class.new(RuntimeError)

      def initialize
        @cache = {}
      end

      def clone(url, name, path: nil, checkout: 'master')
        cached_clone(url, name, path).tap do |git|
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
          git = _clone(from_repo, temp_name("read-file"), path)
          git.checkout(checkout)
          path.join(temp_name("read-file"), filename).read
        end
      end

      def remote_tag(url, tagname, commit_or_object)
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          git = _clone(url, temp_name("tag"), path)
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

      private

      attr_reader :cache

      def temp_name(purpose)
        "bookbinder-git-accessor-#{purpose}"
      end

      def cached_clone(url, name, path)
        cache[[url, name, path]] ||= _clone(url, name, path)
      end

      def _clone(url, name, path)
        Git.clone(url, name, path: path)
      end
    end
  end
end
