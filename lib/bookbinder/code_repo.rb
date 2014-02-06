class CodeRepo < DocRepo
  Store = {}

  def self.get_instance(full_name)
    Store.fetch(full_name) { make(full_name) }
  end

  def self.make(full_name)
    repo = from_remote(repo_hash: {'github_repo' => full_name}, destination_dir: Dir.mktmpdir)
    Store[repo.full_name] = repo
  end

  def get_snippet_at(marker)
    snippet = '' # FileUtils.cd does not return anything.
    FileUtils.cd(copied_to) { snippet = `find . -exec sed -ne '/#{marker}/,/#{marker}/ p' {} \\;` }
    snippet.split("\n")[1..-2].join("\n")
  end
end