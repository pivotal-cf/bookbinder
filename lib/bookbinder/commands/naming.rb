module Bookbinder
  module Commands
    module Naming
      def command_name
        name.demodulize.underscore
      end
    end
  end
end
