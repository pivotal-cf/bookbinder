require_relative '../errors/programmer_mistake'

module Bookbinder
  module Ingest
    class WorkingCopy
      def initialize(copied_to: nil,
                     full_name: nil)
        if [copied_to, full_name].none?
          raise Errors::ProgrammerMistake.new("Must provide copied_to and/or full_name to WorkingCopy.new")
        else
          @copied_to = copied_to
          @full_name = full_name
        end
      end

      attr_reader :full_name

      def available?
        !! @copied_to
      end

      def path
        Pathname(@copied_to)
      end
    end
  end
end
