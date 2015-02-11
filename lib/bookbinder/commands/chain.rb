module Bookbinder
  module Commands
    module Chain
      private

      def command_chain(*commands)
        commands.all? {|command| command[] == 0} ? 0 : 1
      end
    end
  end
end
