require_relative '../../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  module Ingest
    describe WorkingCopy do
      it "is equal to another working copy with same values" do
        expect(WorkingCopy.new(copied_to: 'foo', full_name: 'bar', ref: 'moo')).
          to eq(WorkingCopy.new(copied_to: 'foo', full_name: 'bar', ref: 'moo'))
      end

      it "isn't equal to another working copy with different values" do
        expect(WorkingCopy.new(copied_to: 'baz', full_name: 'bar', ref: 'moo')).
          not_to eq(WorkingCopy.new(copied_to: 'foo', full_name: 'bar', ref: 'moo'))
      end
    end
  end
end
