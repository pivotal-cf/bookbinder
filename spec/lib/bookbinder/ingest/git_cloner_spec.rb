require_relative '../../../../lib/bookbinder/ingest/git_cloner'

module Bookbinder
  module Ingest
    describe GitCloner do
      let(:vcs) { double('version control system') }

      it "copies the repo to the destination, defaulting to master" do
        cloner = GitCloner.new(vcs)
        expect(vcs).to receive(:clone).with("me@mygitplace.com:myorg/myrepo",
                                            "myrepo",
                                            path: "/mydestination",
                                            checkout: "master")

        result = cloner.call(source_repo_name: "me@mygitplace.com:myorg/myrepo",
                             destination_parent_dir: "/mydestination")
        expect(result.directory).to eq("myrepo")
      end

      it "returns an object that is #copied? and has the correct destination" do
        cloner = GitCloner.new(vcs)

        allow(vcs).to receive(:clone)

        result = cloner.call(source_repo_name: "myorg/myrepo",
                             destination_parent_dir: "/mydestination")
        expect(result).to be_copied
        expect(result.copied_to).to eq(Pathname("/mydestination/myrepo"))
      end

      context "when destination_dir_name is provided" do
        it "uses that name as the target leaf dir name" do
          cloner = GitCloner.new(vcs)
          expect(vcs).to receive(:clone).with("git@github.com:myorg/myrepo",
                                              "myspecialreponame",
                                              path: "/mydestination",
                                              checkout: "master")

          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/mydestination",
                               destination_dir_name: "myspecialreponame")

          expect(result.directory).to eq("myspecialreponame")
        end

        it "returns an object that has the correct destination" do
          cloner = GitCloner.new(vcs)

          allow(vcs).to receive(:clone)

          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/mydestination",
                               destination_dir_name: "myawesomedir")
          expect(result.copied_to).to eq(Pathname("/mydestination/myawesomedir"))
        end
      end

      context "when a source ref is specified" do
        it "uses the particular source ref in the clone" do
          cloner = GitCloner.new(vcs)
          expect(vcs).to receive(:clone).
            with("git@github.com:myorg/myrepo",
                 "myrepo",
                 path: "/mydestination",
                 checkout: "mysha")

          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/mydestination",
                      source_ref: "mysha")
        end
      end
    end
  end
end
