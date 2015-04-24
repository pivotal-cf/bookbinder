require_relative '../../../../lib/bookbinder/ingest/working_copy'

module Bookbinder
  module Ingest
    describe WorkingCopy do
      context "when built without a directory" do
        it "uses the repo name as the directory" do
          copy = WorkingCopy.new(directory: nil,
                                 full_name: "myorg/myrepo")
          expect(copy.directory).to eq("myrepo")
        end
      end

      it "is copied if copied location is present" do
        copy = WorkingCopy.new(copied_to: "foo")
        expect(copy).to be_copied
      end

      it "isn't copied if copied location is nil" do
        copy = WorkingCopy.new(copied_to: nil)
        expect(copy).not_to be_copied
      end
    end
  end
end
