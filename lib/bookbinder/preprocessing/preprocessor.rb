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

      def preprocess(objs, *args, &block)
        objs.group_by { |obj|
          processes.detect ->{ NullProcess.new } { |process| process.applicable_to?(obj) }
        }.each do |process, objs|
          process.preprocess(objs, *args)
        end
      end

      private

      attr_reader :processes
    end
  end
end
