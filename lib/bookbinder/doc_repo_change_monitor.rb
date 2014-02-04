class DocRepoChangeMonitor

  include BookbinderLogger

  def initialize(book, cached_sha_dir)
    @cached_sha_dir = cached_sha_dir
    @book = book
    @cached_sha_file = File.join(cached_sha_dir, 'cached_shas.yml')
    @cached_shas = find_cached_shas
  end

  def build_necessary?
    File.open(@cached_sha_file, 'w') { |f| f.write(YAML.dump(head_SHAs_by_repo)) }

    outdated_SHAs = repositories.map do |repo|
      cached_sha = @cached_shas[repo.full_name] || ''
      sha_changed = cached_sha != head_SHAs_by_repo[repo.full_name]
      log "Checked repo #{repo.full_name}:"
      log "  Old SHA: #{sha_color(sha_changed, cached_sha)}"
      log "  New SHA: #{sha_color(sha_changed, head_SHAs_by_repo[repo.full_name])}"
      sha_changed
    end

    log_final_message outdated_SHAs
    outdated_SHAs.any?
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

  def head_SHAs_by_repo
    @shas_by_repo ||= repositories.reduce({}) do |hash, repo|
      hash.merge(repo.full_name => repo.head_sha)
    end
  end

  def find_cached_shas
    File.exist?(@cached_sha_file) ? YAML.load(File.read(@cached_sha_file)) : {}
  end

  def repositories
    @book.constituents + [@book]
  end
end