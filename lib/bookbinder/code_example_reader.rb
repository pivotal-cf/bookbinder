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
            snippet = ""
            Find.find(working_copy.path) do |path|
              if FileTest.directory?(path)
                if File.basename(path)[0] == ?.
                  Find.prune
                else
                  next
                end
              else
                File.open(path, 'r') { |f|
                  start_marker = f.each_line.detect {|l|
                    l.match(/code_snippet #{marker} start/)
                  }
                  if start_marker.nil?
                    Find.prune
                  else
                    return f.tap(&:rewind).read.
                      scan(/(code_snippet #{marker} start.*)code_snippet #{marker} end/m).
                      flatten.first || ""
                  end
                }
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
