class CodeRepo < DocRepo
  class InvalidSnippet < StandardError
    def initialize(repo, marker)
      super "Error with marker #{marker.cyan} #{'in'.red} #{repo.cyan}#{'.'.red}"
    end
  end

  Store = {}

  def self.get_instance(full_name)
    Store.fetch(full_name) { download(full_name) }
  end

  def get_snippet_at(marker)
    snippet = '' # snippet needs to persist through FileUtils.cd scope; buckets!
    FileUtils.cd(copied_to) { snippet = scrape_for(marker) }

    raise InvalidSnippet.new(full_name, marker) if snippet.empty?
    snippet.split("\n")[1..-2].join("\n")
  end

  private

  def self.download(full_name)
    BookbinderLogger.log "Excerpting #{full_name.cyan}"
    repo = from_remote(repo_hash: {'github_repo' => full_name}, destination_dir: Dir.mktmpdir)
    Store[repo.full_name] = repo
  end

  def scrape_for(marker)
    locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
    `#{locale} find . -exec sed -ne '/#{marker}/,/#{marker}/ p' {} \\;`
  end
end