require_relative '../../lib/bookbinder/bookbinder_logger'

module Bookbinder
  class CodeExampleReader
    class InvalidSnippet < StandardError
      def initialize(repo, marker)
        super "Error with marker #{marker.cyan} #{'in'.red} #{repo.cyan}#{'.'.red}"
      end
    end

    def initialize(logger)
      @logger = logger
    end

    def get_snippet_and_language_at(marker, path_to_repository, copied, repo_name)
      unless copied
        logger.log '  skipping (not found) '.magenta + path_to_repository
        return ''
      end

      snippet = ''
      FileUtils.cd(path_to_repository) { locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
      result = `#{locale} find . -exec sed -ne '/code_snippet #{marker} start/,/code_snippet #{marker} end/ p' {} \\; 2> /dev/null`
      result = "" unless result.lines.last && result.lines.last.match(/code_snippet #{marker} end/)
      scrape_for_value = result
      snippet = scrape_for_value }

      raise InvalidSnippet.new(repo_name, marker) if snippet.empty?
      lines = snippet.split("\n")
      language_match = lines[0].match(/code_snippet #{Regexp.escape(marker)} start (\w+)/)
      language = language_match[1] if language_match
      [lines[1..-2].join("\n"), language]
    end

    private

    attr_reader :logger

  end
end