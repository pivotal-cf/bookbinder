module Bookbinder
  module Ingest
    class MissingWorkingCopy
      def path
        Pathname("/this/doesnt/actually/exist/#{SecureRandom.uuid}")
      end

      def available?
        false
      end
    end
  end
end
