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
          cloner.call(from: "myorg/myrepo",
                      parent_dir: "/my/dest")
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
          cloner.call(from: "myorg/myrepo",
                      parent_dir: "/destination/dir")
        end

        it "returns an object that is #copied?" do
          fs = double('filesystem')

          allow(fs).to receive(:file_exist?).
            with(Pathname("/my/repo/dir/myrepo")) { true }
          allow(fs).to receive(:file_exist?).
            with(Pathname("/destination/dir/myrepo")) { false }
          allow(fs).to receive(:copy_contents)

          cloner = LocalFilesystemCloner.new(null_logger, fs, "/my/repo/dir")
          result = cloner.call(from: "myorg/myrepo",
                               parent_dir: "/destination/dir")

          expect(result).to be_copied
        end

        context "but it's already been copied" do
          it "returns an object that is #copied?, but doesn't perform the copy" do
            fs = double('filesystem')

            allow(fs).to receive(:file_exist?).
              with(Pathname("/my/repo/dir/myrepo")) { true }
            allow(fs).to receive(:file_exist?).
              with(Pathname("/destination/dir/myrepo")) { true }

            cloner = LocalFilesystemCloner.new(null_logger, fs, "/my/repo/dir")
            result = cloner.call(from: "myorg/myrepo",
                                 parent_dir: "/destination/dir")

            expect(result).to be_copied
          end
        end
      end

      context "when the local repo isn't present" do
        it "logs the fact that it isn't copying anything, and doesn't copy" do
          fs = double('filesystem', file_exist?: false)
          logger = double('logger')

          expect(logger).to receive(:log).with(%r{ skipping .*/my/repo/dir})

          cloner = LocalFilesystemCloner.new(logger, fs, "/my/repo/dir")
          cloner.call(from: "myorg/myrepo",
                      parent_dir: "/some/dest")
        end

        it "returns an object that isn't #copied?" do
          fs = double('filesystem', file_exist?: false)
          logger = double('logger')

          allow(logger).to receive(:log) { nil } # #log returns nil, because puts returns nil

          cloner = LocalFilesystemCloner.new(logger, fs, "/my/repo/dir")
          result = cloner.call(from: "myorg/myrepo",
                               parent_dir: "/some/dest")
          expect(result).not_to be_copied
        end
      end
    end
  end
end
