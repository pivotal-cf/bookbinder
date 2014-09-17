require 'git'

module Bookbinder
  class GitObjectFixture

    # this needs to be a copy of a Git object returned by Git.clone
    # so we can return it when stubbing Git.receive(:clone) and have
    # all methods and content available to test
    # without stubbing every darn thing

    def self.get_instance(uri, path)
      # would it work here to clone a git repo and set it as an instance variable for future retrievals?
      # e.g.

      # @git ||= Git.clone('Duckburg/scrooge')
    end

    # Otherwise will have to retain a dir that is already cloned and then generate the git object from it?
    def initialize(cloned_dir)
      git_repo = Git.init(cloned_dir)
    end




  end
end