class CodeRepo < DocRepo
  class InvalidSnippet < StandardError
    def initialize(repo, marker)
      super "Error with marker #{marker.cyan} #{'in'.red} #{repo.cyan}#{'.'.red}"
    end
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

  def scrape_for(marker)
    locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
    result = `#{locale} find . -exec sed -ne '/code_snippet #{marker} start/,/code_snippet #{marker} end/ p' {} \\;`
    result = "" unless result.lines.last && result.lines.last.match(/code_snippet #{marker} end/)
    result
  end
end
