class LocalDocReposUpdater

  include ShellOut
  include BookbinderLogger

  def update(repos, local_repo_dir)
    repos.each do |repo_hash|
      doc_repo = DocRepo.from_local repo_hash: repo_hash, local_dir: local_repo_dir
      repo_dir = File.join(local_repo_dir, doc_repo.name)

      if File.exist?(repo_dir)
        log 'Updating ' + repo_dir.cyan
        system "cd #{repo_dir} && git pull"
      else
        log 'Skipping (non-existent) '.magenta + repo_dir.cyan
      end
    end
  end
end