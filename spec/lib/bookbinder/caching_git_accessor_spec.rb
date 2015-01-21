require 'pathname'
require 'tmpdir'
require_relative '../../helpers/git_repo'
require_relative '../../../lib/bookbinder/caching_git_accessor'

module Bookbinder
  describe CachingGitAccessor do
    include GitRepo

    it "clones to a given dir" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcgorepo'),
                  file: 'foo',
                  contents: 'bar',
                  commit_message: 'baz')
        CachingGitAccessor.new.clone(path.join("srcgorepo"), 'destgorepo', path: path)
        expect(File.read(path.join('destgorepo', 'foo'))).to eq("bar\n")
      end
    end

    it "only clones once for a given set of params" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcrepo'),
                  file: 'Gemfile',
                  contents: 'gemstuffz',
                  commit_message: 'new railz plz')

        git = CachingGitAccessor.new

        git.clone(path.join('srcrepo'), 'destrepo', path: path)
        expect { git.clone(path.join('srcrepo'), 'destrepo', path: path) }.
          not_to change { File.mtime(path.join('destrepo', 'Gemfile')) }
      end
    end
  end
end
