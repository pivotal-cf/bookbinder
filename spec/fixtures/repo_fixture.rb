class RepoFixture

  extend ShellOut

  def self.tarball(name, sha)
    tmpdir = Dir.mktmpdir
    FileUtils.cp_r File.join(repos_dir, name), File.join(tmpdir, "#{name}-#{sha}")
    tarball_path = File.join(tmpdir, "#{name}-master.tgz")
    shell_out "cd #{tmpdir} && tar czf #{tarball_path} #{name}-#{sha}"
    File.read(tarball_path)
  end

  def self.repos_dir
    File.join(GEM_ROOT, 'spec', 'fixtures', 'repositories')
  end
end
