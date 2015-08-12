module Bookbinder
  module Preprocessing
    class Preprocessor
      class NullProcess
        def preprocess(*)
        end
      end

      def initialize(*processes)
        @processes = processes
      end

      def preprocess(sections, *args)
        sections.group_by { |section|
          processes.detect ->{ NullProcess.new } { |process| process.applicable_to?(section) }
        }.each do |process, grouped_sections|
          process.preprocess(grouped_sections, *args)
        end
      end

      private

      attr_reader :processes
    end
  end
end
