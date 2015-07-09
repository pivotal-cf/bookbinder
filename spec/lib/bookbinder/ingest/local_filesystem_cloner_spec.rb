require_relative '../../../../lib/bookbinder/ingest/local_filesystem_cloner'

module Bookbinder
  module Ingest
    describe LocalFilesystemCloner do
      context "when the local repo is present" do
        it "logs the fact that it's copying" do
          fs = double('filesystem')
          out = StringIO.new

          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/repo/dir/myrepo")) { true }
          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/dest/myrepo")) { false }
          allow(fs).to receive(:copy_contents)

          cloner = LocalFilesystemCloner.new({out: out}, fs, "/my/repo/dir")
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/my/dest")
          expect(out.tap(&:rewind).read).to match(%r{ copying.*/my/repo/dir})
        end

        it "copies the repo to the destination" do
          fs = double('filesystem')

          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/repo/dir/myrepo")) { true }
          allow(fs).to receive(:file_exist?).
            with(Pathname("/destination/dir/myrepo")) { false }

          expect(fs).to receive(:copy_contents).
            with(Pathname("/my/repo/dir/myrepo"),
                 Pathname("/destination/dir/myrepo"))

          cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, "/my/repo/dir")
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/destination/dir")
        end

        context "when destination directory name is set" do
          it "copies the repo to the custom directory" do
            fs = double('filesystem')

            allow(fs).to receive(:file_exist?).
              with(Pathname("/sourceparent/sourcerepo")) { true }
            allow(fs).to receive(:file_exist?).
              with(Pathname("/destparent/mycustomdestrepo")) { false }

            expect(fs).to receive(:copy_contents).
              with(Pathname("/sourceparent/sourcerepo"),
                   Pathname("/destparent/mycustomdestrepo"))

            cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, "/sourceparent")
            cloner.call(source_repo_name: "myorg/sourcerepo",
                        destination_dir_name: 'mycustomdestrepo',
                        destination_parent_dir: "/destparent")
          end
        end

        it "returns an object that is has the correct destination" do
          fs = double('filesystem')

          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/repo/dir/myrepo")) { true }
          allow(fs).to receive(:file_exist?).
            with(Pathname("/destination/dir/myrepo")) { false }
          allow(fs).to receive(:copy_contents)

          cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, "/my/repo/dir")
          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/destination/dir")

          expect(result.path).to eq(Pathname("/destination/dir/myrepo"))
        end
      end

      context "when the local repo isn't present" do
        it "logs the fact that it isn't copying anything, and doesn't copy" do
          fs = double('filesystem', file_exist?: false)
          out = StringIO.new
          cloner = LocalFilesystemCloner.new({out: out}, fs, "/my/repo/dir")
          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/some/dest")
          expect(result.path).not_to exist
          expect(result).not_to be_available
          expect(result.full_name).to eq('myorg/myrepo')
          expect(out.tap(&:rewind).read).to match(%r{ skipping .*/my/repo/dir})
        end
      end
    end
  end
end
