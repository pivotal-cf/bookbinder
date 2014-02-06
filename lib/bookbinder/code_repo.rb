class CodeRepo
  Store = {}

  def self.get_instance(full_name)
    Store.fetch(full_name) { make(full_name) }
  end

  def self.make(full_name)
    repo = DocRepo.from_remote(repo_hash: {'github_repo' => full_name}, destination_dir: Dir.mktmpdir)
    Store[repo.full_name] = repo
  end
end