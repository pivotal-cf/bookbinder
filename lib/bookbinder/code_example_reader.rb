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
        out.puts("  skipping (not found) #{working_copy.full_name}")
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
      snippet = Snippet.new(
        find_text(working_copy.path, pattern_for(marker)),
        language_pattern_for(marker)
      )
      if snippet.valid?
        [snippet.content, snippet.language]
      else
        raise InvalidSnippet.new(working_copy.full_name, marker)
      end
    end

    def find_text(start_path, pattern)
      fs.find_files_recursively(start_path).
        lazy.
        select {|path| fs.file_exist?(path) }.
        map {|path| fs.read(path) }.
        map {|contents|
          begin
            contents.scan(pattern)
          rescue ArgumentError => e
            cannot_scan
          end
        }.
        map(&:first).
        detect ->{""} {|text| text}
    end

    def pattern_for(marker)
      /code_snippet #{Regexp.escape(marker)} start.*code_snippet #{Regexp.escape(marker)} end/m
    end

    def language_pattern_for(marker)
      /code_snippet #{Regexp.escape(marker)} start (\w+)/
    end

    def cannot_scan
      []
    end
  end
end
