class CodeRepo < DocRepo
  class InvalidSnippet < StandardError
    def initialize(repo, marker)
      super "Error with marker #{marker.cyan} #{'in'.red} #{repo.cyan}#{'.'.red}"
    end
  end

  Store = {}

  def self.get_instance(full_name, local_repo_dir=nil)
    Store.fetch([full_name, local_repo_dir]) { acquire(full_name, local_repo_dir) }
  end

  def get_snippet_and_language_at(marker)
    copied? ? prepared_snippet_at(marker) : noisy_failure
  end

  private

  def noisy_failure
    announce_skip
    ''
  end

  def prepared_snippet_at(marker)
    snippet = ''
    FileUtils.cd(copied_to) { snippet = scrape_for(marker) }

    raise InvalidSnippet.new(full_name, marker) if snippet.empty?
    lines = snippet.split("\n")
    language_match = lines[0].match(/code_snippet #{Regexp.escape(marker)} start (\w+)/)
    language = language_match[1] if language_match
    [lines[1..-2].join("\n"), language]
  end

  def self.acquire(full_name, local_repo_dir)
    BookbinderLogger.log "Excerpting #{full_name.cyan}"
    repo = local_repo_dir ? copy(full_name, local_repo_dir) : download(full_name)
    keep(repo, local_repo_dir) if repo
  end

  def self.keep(repo, local_repo_dir)
    Store[[repo.full_name, local_repo_dir]] = repo
  end

  def self.download(full_name)
    from_remote({repo_hash: {'github_repo' => full_name}, destination_dir: Dir.mktmpdir})
  end

  def self.copy(full_name, local_repo_dir)
    from_local(repo_hash: {'github_repo' => full_name}, local_dir: local_repo_dir, destination_dir: Dir.mktmpdir)
  end

  def scrape_for(marker)
    locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
    `#{locale} find . -exec sed -ne '/code_snippet #{marker} start/,/code_snippet #{marker} end/ p' {} \\;`
  end
end
