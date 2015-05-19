require_relative '../../../../lib/bookbinder/preprocessing/preprocessor'

module Bookbinder
  module Preprocessing
    describe Preprocessor do
      it "applies processes to applicable objects" do
        objs = [
          Object.new,
          Object.new,
          Object.new,
          Object.new,
        ]

        process_1 = double('process 1')
        process_2 = double('process 2')

        preprocessor = Preprocessor.new(process_1, process_2)

        allow(process_1).to receive(:applicable_to?) { |obj| objs[0..1].include?(obj) }
        allow(process_2).to receive(:applicable_to?) { |obj| objs[2..3].include?(obj) }

        expect(process_1).to receive(:preprocess).with(objs[0..1], 'extra', 'args')
        expect(process_2).to receive(:preprocess).with(objs[2..3], 'extra', 'args')

        preprocessor.preprocess(objs, 'extra', 'args')
      end

      it "applies the default process to objects that aren't applicable to any process" do
        objs = [
          Object.new,
          Object.new,
          Object.new,
          Object.new,
        ]

        process_1 = double('default process')
        process_2 = double('some other process')

        preprocessor = Preprocessor.new(process_2, default: process_1)

        block = ->(*){}

        allow(process_1).to receive(:applicable_to?) { false }
        allow(process_2).to receive(:applicable_to?) { |obj| objs[2..3].include?(obj) }

        expect(process_1).to receive(:preprocess).with(objs[0..1], 'extra', 'args')
        expect(process_2).to receive(:preprocess).with(objs[2..3], 'extra', 'args')

        preprocessor.preprocess(objs, 'extra', 'args')
      end
    end
  end
end

