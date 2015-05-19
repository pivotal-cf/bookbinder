module Bookbinder
  module Preprocessing
    class Preprocessor
      def initialize(*processes, default: nil)
        @processes = processes
        @default = default
      end

      def preprocess(objs, *args, &block)
        objs.group_by { |obj|
          processes.detect ->{ default } { |process| process.applicable_to?(obj) }
        }.each do |process, objs|
          process.preprocess(objs, *args)
        end
      end

      private

      attr_reader :processes, :default
    end
  end
end
