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
      if working_copy.available?
        process_snippet(marker, working_copy)
      else
        out << "  skipping (not found) #{working_copy.full_name}"
        ''
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
      escaped_marker = Regexp.escape(marker)
      pattern = /code_snippet #{escaped_marker} start.*code_snippet #{escaped_marker} end/m
      language_pattern = /code_snippet #{escaped_marker} start (\w+)/

      found_text = fs.find_files_recursively(working_copy.path).
        lazy.map {|path| fs.read(path).scan(pattern).first}.
        detect ->{""} {|lines| lines}

      snippet = Snippet.new(found_text, language_pattern)

      if snippet.valid?
        [snippet.content, snippet.language]
      else
        raise InvalidSnippet.new(working_copy.full_name, marker)
      end
    end
  end
end
