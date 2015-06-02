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
    end
  end
end
