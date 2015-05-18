require_relative '../../../../lib/bookbinder/ingest/destination_directory'

module Bookbinder
  module Ingest
    describe DestinationDirectory do
      it "is empty if instantiated with nils" do
        expect(DestinationDirectory.new).to eq("")
      end

      context "when not given a desired destination name" do
        it "returns the repo part of an org/repo type name" do
          expect(DestinationDirectory.new("myorg/myrepo")).to eq("myrepo")
        end

        it "returns the repo part of an https:// type name" do
          expect(DestinationDirectory.new("https://bitbucket.foo/myorg/myrepo")).to eq("myrepo")
        end

        it "returns the repo part of a git@github type name" do
          expect(DestinationDirectory.new("git@github.com:camelpunch/potato")).to eq("potato")
        end
      end

      context "when given a desired destination dir name" do
        it "uses that" do
          expect(DestinationDirectory.new("some@repo.place:i/dontwant", "dowant")).to eq("dowant")
        end

        it "doesn't use that if it's nil" do
          expect(DestinationDirectory.new("some@repo.place:i/dowant", nil)).to eq("dowant")
        end
      end
    end
  end
end

