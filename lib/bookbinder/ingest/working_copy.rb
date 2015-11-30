require_relative '../errors/programmer_mistake'

module Bookbinder
  module Ingest
    class WorkingCopy
      attr_reader :full_name, :ref

      def initialize(copied_to: nil,
                     full_name: nil,
                     ref: nil)
        if [copied_to, full_name].none?
          raise Errors::ProgrammerMistake.new("Must provide copied_to and/or full_name to WorkingCopy.new")
        else
          @copied_to = copied_to
          @full_name = full_name
          @ref = ref
        end
      end

      def available?
        !! @copied_to
      end

      def path
        Pathname(@copied_to)
      end

      def ==(other)
        [@copied_to, @full_name, @ref] ==
          [other.instance_variable_get(:@copied_to),
           other.instance_variable_get(:@full_name),
           other.instance_variable_get(:@ref)]
      end
    end
  end
end
