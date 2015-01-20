require 'pathname'
require 'tmpdir'
require_relative '../../../lib/bookbinder/caching_git_accessor'

module Bookbinder
  describe CachingGitAccessor do
    def init_repo(at_dir: nil, file: nil, contents: nil, commit_message: nil)
      FileUtils.mkdir(at_dir)
      `#{<<-SCRIPT}`
      cd #{at_dir};
      git init;
      git config user.email "you@example.com"
      git config user.name "Your name"
      echo #{contents} > #{file}; git add .; git commit -m "#{commit_message}"
      SCRIPT
    end

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
