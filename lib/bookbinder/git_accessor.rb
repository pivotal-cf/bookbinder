require 'git'

module Bookbinder
  class GitAccessor
    def initialize
      @cache = {}
    end

    def clone(url, name, path: nil, checkout: 'master')
      cached_clone(url, name, path).tap do |git|
        git.checkout(checkout)
      end
    end

    def read_file(filename, from_repo: nil, checkout: 'master')
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        git = _clone(from_repo, "read-file", path)
        git.checkout(checkout)
        path.join("read-file", filename).read
      end
    end

    private

    attr_reader :cache

    def cached_clone(url, name, path)
      cache[[url, name, path]] ||= _clone(url, name, path)
    end

    def _clone(url, name, path)
      Git.clone(url, name, path: path)
    end
  end
end
