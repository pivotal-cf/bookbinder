class DocRepoChangeMonitor

  include BookbinderLogger

  def initialize(repo_hashes, cached_sha_dir)
    @repo_full_names = repo_hashes.map { |repo_hash| repo_hash["github_repo"] }
    @cached_sha_dir = cached_sha_dir
    @repos = repo_hashes.map do |repo_hash|
      DocRepo.from_remote repo_hash: repo_hash
    end
    @cached_sha_file = File.join(cached_sha_dir, 'cached_shas.yml')
    @cached_shas = find_cached_shas
  end

  def build_necessary?
    head_shas_by_repo = fetch_head_SHAs_by_repo
    yaml = YAML.dump(head_shas_by_repo)
    File.open(@cached_sha_file, 'w') { |f| f.write(yaml) }
    shas_not_up_to_date = @repo_full_names.map do |repo_full_name|
      cached_sha = @cached_shas[repo_full_name] || ''
      sha_changed = cached_sha != head_shas_by_repo[repo_full_name]
      log "Checked repo #{repo_full_name}:"
      log "  Old SHA: #{sha_color(sha_changed, cached_sha)}"
      log "  New SHA: #{sha_color(sha_changed, head_shas_by_repo[repo_full_name])}"
      sha_changed
    end

    log_final_message shas_not_up_to_date
    shas_not_up_to_date.any?
  end

  private

  def sha_color(build_necessary_for_this_repo, cached_sha)
    build_necessary_for_this_repo ? cached_sha.yellow : cached_sha
  end

  def log_final_message(shas_not_up_to_date)
    if shas_not_up_to_date.any?
      log "\nThe repos have changed, triggering a rebuild!".green
    else
      log "\nThe repos haven't changed, no build necessary".red
    end
  end

  def fetch_head_SHAs_by_repo
    head_shas_as_array = @repos.map { |repo| [repo.full_name, repo.sha] }
    Hash[*head_shas_as_array.flatten]
  end

  def find_cached_shas
    File.exist?(@cached_sha_file) ? YAML.load(File.read(@cached_sha_file)) : {}
  end

end