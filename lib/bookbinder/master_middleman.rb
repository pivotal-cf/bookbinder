class MasterMiddleman
  def self.path(logger, local_repo_dir, repo_name)
    section = {'repository' => {'name' => repo_name}}
    directory = Section.get_instance(logger, section_hash: section, local_repo_dir: local_repo_dir).directory
    File.join(local_repo_dir, directory)
  end
end