class MarkdownRepoFixture

  extend ShellOut

  def self.tarball(name, sha)
    tmpdir = Dir.mktmpdir
    tarball_path = File.join(tmpdir, "#{name}-master.tgz")
    shell_out "cd #{markdown_repos_dir} && tar czf #{tarball_path} #{name}-#{sha}"
    File.read(tarball_path)
  end

  def self.copy_to_tmp_repo_dir
    local_repo_dir = Dir.mktmpdir
    FileUtils.cp_r File.join(markdown_repos_dir, 'my-docs-repo-some-sha'), File.join(local_repo_dir, 'my-docs-repo')
    FileUtils.cp_r File.join(markdown_repos_dir, 'my-other-docs-repo-some-other-sha'), File.join(local_repo_dir, 'my-other-docs-repo')
    local_repo_dir
  end

  private

  def self.markdown_repos_dir
    File.join('spec', 'fixtures', 'markdown_repos')
  end

end