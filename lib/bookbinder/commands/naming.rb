module Bookbinder
  module Commands
    module Naming
      def command_name
        self.class.name.demodulize.underscore
      end
    end
  end
end
