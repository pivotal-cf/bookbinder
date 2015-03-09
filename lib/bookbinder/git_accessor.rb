require 'git'

module Bookbinder
  class GitAccessor
    def initialize
      @cache = {}
    end

    def clone(url, name, path: nil)
      cache[[url, name, path]] ||= Git.clone(url, name, path: path)
    end

    private

    attr_reader :cache
  end
end
