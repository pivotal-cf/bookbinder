require_relative 'local_file_system_accessor'

module Bookbinder
  class CodeExampleReader
    class InvalidSnippet < StandardError
      def initialize(repo, marker)
        super "Error with marker #{marker} in #{repo}."
      end
    end

    def initialize(streams, fs)
      @out = streams[:out]
      @fs = fs
    end

    def get_snippet_and_language_at(marker, working_copy)
      if ! working_copy.available?
        out << "  skipping (not found) #{working_copy.full_name}"
        ''
      else
        process_snippet(marker, working_copy)
      end
    end

    class Snippet
      def initialize(text, language_pattern)
        @text = text
        @language_pattern = language_pattern
      end

      def valid?
        ! text.empty?
      end

      def language
        language_match = lines[0].match(language_pattern)
        Array(language_match)[1]
      end

      def content
        lines[1..-2].join("\n").strip
      end

      private

      attr_reader :text, :language_pattern

      def lines
        text.split("\n")
      end
    end

    private

    attr_reader :out, :fs

    def process_snippet(marker, working_copy)
      snippet = Snippet.new(
        fs.find_lines_recursively(
          working_copy.path,
          /code_snippet #{marker} start.*code_snippet #{marker} end/m
        ),
        /code_snippet #{Regexp.escape(marker)} start (\w+)/
      )
      if snippet.valid?
        [snippet.content, snippet.language]
      else
        raise InvalidSnippet.new(working_copy.full_name, marker)
      end
    end
  end
end
