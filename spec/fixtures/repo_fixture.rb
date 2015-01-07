require 'bookbinder/shell_out'

module Bookbinder
  class RepoFixture
    extend Bookbinder::ShellOut

    def self.tarball(name, sha)
      repo_dir, tarball_path, tmpdir = copy_out(name, sha)

      yield(repo_dir) if block_given?

      zip(name, sha, tarball_path, tmpdir)

      File.read(tarball_path)
    end

    def self.repos_dir
      File.expand_path('../repositories', __FILE__)
    end

    private


    def self.copy_out(name, sha)
      tmpdir = Dir.mktmpdir
      repo_dir = File.join(tmpdir, "#{name}-#{sha}")
      FileUtils.cp_r File.join(repos_dir, name), repo_dir
      tarball_path = File.join(tmpdir, "#{name}-master.tgz")
      return repo_dir, tarball_path, tmpdir
    end

    def self.zip(name, sha, tarball_path, tmpdir)
      shell_out "cd #{tmpdir} && tar czf #{tarball_path} #{name}-#{sha}"
    end
  end
end
