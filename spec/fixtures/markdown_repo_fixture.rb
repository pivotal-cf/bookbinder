class MarkdownRepoFixture

  extend ShellOut

  def self.tarball(name, sha)
    tmpdir = Dir.mktmpdir
    FileUtils.cp_r File.join(markdown_repos_dir, name), File.join(tmpdir, "#{name}-#{sha}")
    tarball_path = File.join(tmpdir, "#{name}-master.tgz")
    shell_out "cd #{tmpdir} && tar czf #{tarball_path} #{name}-#{sha}"
    File.read(tarball_path)
  end

  def self.markdown_repos_dir
    File.join('spec', 'fixtures', 'markdown_repos')
  end
end