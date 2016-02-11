module Bookbinder
  module Preprocessing
    class DitaPreprocessor

      protected

      def dita_flags(opts)
        matching_flags = opts.map {|o| o[flag_value_regex("dita-flags"), 1] }
        matching_flags.compact.first
      end

      def flag_value_regex(flag_name)
        Regexp.new(/--#{flag_name}="(.+)"/)
      end
    end
  end
end
