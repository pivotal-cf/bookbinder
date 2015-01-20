require 'git'

module Bookbinder
  class CachingGitAccessor
    def initialize
      @cache = {}
    end

    def clone(url, name, path: nil)
      cache[[url, name, path]] ||= Git.clone(url, name, path: path)
    end

    private

    attr_reader :cache, :third_party
  end
end
