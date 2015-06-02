module Bookbinder
  class RepoFixture
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
  end
end
