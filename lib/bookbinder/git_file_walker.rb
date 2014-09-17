require 'git'

module Bookbinder
  class GitFileWalker

    def initialize(git_object)
      @git = git_object
    end

    # Return a hash of path => last update sha.
    def shas_by_file
      result = {}
      files = files_by_tree(@git.gtree('HEAD'))
      files.each do |file|
        result[file] = file_sha(file)
      end
      result
    end

    private

    # Given a Git::Object::Tree, return an array of all paths in the tree.
    def files_by_tree(tree, path='')
      blob_files = tree.blobs.keys.map { |name| File.join(path, name).sub(%r{^/}, '') }

      tree.subtrees.inject(blob_files) do |memo, child|
        subtree_name, subtree = child
        memo.concat(files_by_tree(subtree, File.join(path, subtree_name)))
      end
    end

    def file_sha(file)
      @git.log.object(file).first.sha
    end
  end
end