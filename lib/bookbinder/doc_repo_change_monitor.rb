class DocRepoChangeMonitor

  include BookbinderLogger

  def initialize(book, cached_sha_dir)
    @cached_sha_dir = cached_sha_dir
    @book = book
    @cached_sha_file = File.join(cached_sha_dir, 'cached_shas.yml')
  end

  def build_necessary?
    anachronicity = repositories.map { |repo| sha_changed? cached_SHAs, repo }
    cache_new_SHAs

    log_final_message anachronicity
    anachronicity.any?
  end

  private

  def sha_changed?(cache, repo)
    cached_sha = cache[repo.full_name] || ''
    sha_changed = cached_sha != repo.head_sha

    log "Checked repo #{repo.full_name.cyan}:"
    log "  Old SHA: #{sha_color(sha_changed, cached_sha)}"
    log "  New SHA: #{sha_color(sha_changed, repo.head_sha)}"

    sha_changed
  end

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

  def head_SHAs_by_repo
    repositories.reduce({}) do |hash, repo|
      hash.merge(repo.full_name => repo.head_sha)
    end
  end

  def cached_SHAs
    File.exist?(@cached_sha_file) ? YAML.load(File.read(@cached_sha_file)) : {}
  end

  def cache_new_SHAs
    File.open(@cached_sha_file, 'w') { |f| f.write(YAML.dump(head_SHAs_by_repo)) }
  end

  def repositories
    @book.constituents + [@book]
  end
end