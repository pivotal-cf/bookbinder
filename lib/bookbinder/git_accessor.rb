require 'git'

module Bookbinder
  class GitAccessor
    def initialize
      @cache = {}
    end

    def clone(url, name, path: nil, checkout: 'master')
      cache[[url, name, path]] ||= Git.clone(url, name, path: path).tap do |git|
        git.checkout(checkout)
      end
    end

    private

    attr_reader :cache
  end
end
