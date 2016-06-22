module Bookbinder
  module Postprocessing
    class Redirection
      def initialize(fs, file_path)
        @redirect_regexes = {}
        @redirect_strings = {}
        load!(fs, file_path)
      end

      def redirected?(url)
        @redirect_strings.has_key?(url) ||
          @redirect_regexes.keys.detect {|regex| regex.match(url)}
      end

      private

      def load!(fs, file_path)
        if fs.is_file?(file_path)
          contents = fs.read(file_path)
          instance_eval contents
        end
      end

      def r301(source, dest, options={})
        return if options.has_key?(:if)

        case source
        when Regexp
          @redirect_regexes[source] = dest
        when String
          @redirect_strings[source] = dest
        end
      end
      alias r302 r301
      alias rewrite r301
    end
  end
end
