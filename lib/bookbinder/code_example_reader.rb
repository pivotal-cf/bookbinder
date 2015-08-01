require 'find'

module Bookbinder
  class CodeExampleReader
    class InvalidSnippet < StandardError
      def initialize(repo, marker)
        super "Error with marker #{marker} in #{repo}."
      end
    end

    def initialize(out: nil)
      @out = out
    end

    def get_snippet_and_language_at(marker, working_copy)
      snippet = Snippet.new(marker, working_copy)
      if snippet.available? && !snippet.valid?
        raise InvalidSnippet.new(working_copy.full_name, marker)
      elsif snippet.available?
        [snippet.content, snippet.language]
      else
        out << "  skipping (not found) #{working_copy.full_name}"
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
        ! snippet.empty?
      end

      def language
        language_match = lines[0].match(/code_snippet #{Regexp.escape(marker)} start (\w+)/)
        Array(language_match)[1]
      end

      def content
        lines[1..-2].join("\n")
      end

      private

      attr_reader :marker, :working_copy

      def lines
        snippet.split("\n")
      end

      def snippet
        @snippet ||=
          begin
            snippet = ""
            pattern = /code_snippet #{marker} start.*code_snippet #{marker} end/m
            from = working_copy.path

            Find.find(from) do |dir|
              path = Pathname(dir)
              if path.directory? && path.basename.to_s[0] == ?.
                Find.prune
              elsif path.directory?
                next
              else
                scanned, * = path.read.scan(pattern)
                if scanned
                  return scanned
                else
                  Find.prune
                end
              end
            end
            snippet
          end
      end
    end

    private

    attr_reader :out
  end
end
