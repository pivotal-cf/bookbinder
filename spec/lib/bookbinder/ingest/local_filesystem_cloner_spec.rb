require_relative '../../../../lib/bookbinder/ingest/local_filesystem_cloner'

module Bookbinder
  module Ingest
    describe LocalFilesystemCloner do
      context "when the local repo is present" do
        let(:null_logger) { double('null logger').as_null_object }

        it "logs the fact that it's copying" do
          fs = double('filesystem')
          logger = double('logger')

          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/repo/dir/myrepo")) { true }
          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/dest/myrepo")) { false }
          allow(fs).to receive(:copy_contents)

          expect(logger).to receive(:log).with(%r{ copying.*/my/repo/dir})

          cloner = LocalFilesystemCloner.new(logger, fs, "/my/repo/dir")
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/my/dest")
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

          cloner = LocalFilesystemCloner.new(null_logger, fs, "/my/repo/dir")
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

            cloner = LocalFilesystemCloner.new(null_logger, fs, "/sourceparent")
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

          cloner = LocalFilesystemCloner.new(null_logger, fs, "/my/repo/dir")
          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/destination/dir")

          expect(result.path).to eq(Pathname("/destination/dir/myrepo"))
        end
      end

      context "when the local repo isn't present" do
        it "logs the fact that it isn't copying anything, and doesn't copy" do
          fs = double('filesystem', file_exist?: false)
          logger = double('logger')

          expect(logger).to receive(:log).with(%r{ skipping .*/my/repo/dir})

          cloner = LocalFilesystemCloner.new(logger, fs, "/my/repo/dir")
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/some/dest")
        end
      end
    end
  end
end
