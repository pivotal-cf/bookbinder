require_relative '../../lib/bookbinder/deprecated_logger'

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

    def get_snippet_and_language_at(marker, working_copy)
      snippet = Snippet.new(marker, working_copy)
      if snippet.available? && !snippet.valid?
        raise InvalidSnippet.new(working_copy.full_name, marker)
      elsif snippet.available?
        [snippet.content, snippet.language]
      else
        logger.log '  skipping (not found) '.magenta + working_copy.full_name
        ''
      end
    end

    class Snippet
      def initialize(marker, working_copy)
        @marker = marker
        @working_copy = working_copy
      end

      def available?
        working_copy.available?
      end

      def valid?
        ! get_snippet(marker, working_copy).empty?
      end

      def language
        lines = get_snippet(marker, working_copy).split("\n")
        language_match = lines[0].match(/code_snippet #{Regexp.escape(marker)} start (\w+)/)
        Array(language_match)[1]
      end

      def content
        lines = get_snippet(marker, working_copy).split("\n")
        lines[1..-2].join("\n")
      end

      private

      attr_reader :marker, :working_copy

      def get_snippet(marker, working_copy)
        @snippet ||=
          begin
            snippet = ''
            FileUtils.cd(working_copy.copied_to) {
              locale = 'LC_CTYPE=C LANG=C' # Quiets 'sed: RE error: illegal byte sequence'
              result = `#{locale} find . -exec sed -ne '/code_snippet #{marker} start/,/code_snippet #{marker} end/ p' {} \\; 2> /dev/null`
              snippet = if result.lines.last && result.lines.last.match(/code_snippet #{marker} end/)
                          result
                        else
                          ""
                        end
            }
            snippet
          end
      end
    end

    private

    attr_reader :logger
  end
end
