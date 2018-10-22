require_relative '../../../../lib/bookbinder/ingest/local_filesystem_cloner'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'

require 'tmpdir'
require 'fileutils'
require 'pp'
require 'fakefs/spec_helpers'

module Bookbinder
  module Ingest
    describe LocalFilesystemCloner do
      include FakeFS::SpecHelpers

      let(:user_repo_dir) { "/my/repo/dir" }
      let(:fs) { LocalFilesystemAccessor.new }

      def user_repo_mkdir(name)
        FileUtils.mkdir_p(File.join(user_repo_dir, name))
      end

      context "when the local repo is present" do
        it "logs the fact that it's cloning" do
          out = StringIO.new

          user_repo_mkdir('myrepo')
          allow(fs).to receive(:link_creating_intermediate_dirs)

          cloner = LocalFilesystemCloner.new({out: out}, fs, user_repo_dir)
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/my/dest")
          expect(out.string).to match(%r{ copying.*/my/repo/dir})
        end

        it "links the repo to the destination" do
          user_repo_mkdir('myrepo')
          allow(fs).to receive(:link_creating_intermediate_dirs).
            with(Pathname("/my/repo/dir/myrepo"),
                 Pathname("/destination/dir/myrepo"))

          cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, user_repo_dir)
          cloner.call(source_repo_name: "myorg/myrepo",
                      destination_parent_dir: "/destination/dir")
        end

        context "when destination directory name is set" do
          it "copies the repo to the custom directory" do
            user_repo_mkdir('sourcerepo')

            expect(fs).to receive(:link_creating_intermediate_dirs).
              with(Pathname("/my/repo/dir/sourcerepo"),
                   Pathname("/destparent/mycustomdestrepo"))

            cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, user_repo_dir)
            cloner.call(source_repo_name: "myorg/sourcerepo",
                        destination_dir_name: 'mycustomdestrepo',
                        destination_parent_dir: "/destparent")
          end
        end

        it "returns an object that is has the correct destination" do
          user_repo_mkdir('myrepo')
          allow(fs).to receive(:link_creating_intermediate_dirs)

          cloner = LocalFilesystemCloner.new({out: StringIO.new}, fs, user_repo_dir)
          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/destination/dir")

          expect(result.path).to eq(Pathname("/destination/dir/myrepo"))
        end
      end

      context "when the local repo isn't present" do
        it "logs the fact that it isn't copying anything, and doesn't copy" do
          out = StringIO.new
          cloner = LocalFilesystemCloner.new({out: out}, fs, user_repo_dir)
          result = cloner.call(source_repo_name: "myorg/myrepo",
                               destination_parent_dir: "/some/dest")
          expect(result.path).not_to exist
          expect(result).not_to be_available
          expect(result.full_name).to eq('myorg/myrepo')
          expect(out.string).to match(%r{ skipping .*/my/repo/dir})
        end
      end

      context 'when the local repo directory name includes the ref' do
        it 'links to the correct file' do
          user_repo_mkdir("repo-ref")
          user_repo_mkdir("repo-myorg-ref")
          FileUtils.mkdir_p("/destination")

          out = StringIO.new
          cloner = LocalFilesystemCloner.new({out: out}, fs, user_repo_dir)

          result = cloner.call(source_repo_name: "myorg/repo",
                               source_ref: "ref",
                               destination_parent_dir: "/destination",
                               destination_dir_name: "reps")

          expect(fs.file_exist?(result.path)).to be true
          expect(out.string).to match(%r{ copying\s*/my/repo/dir/repo-ref})
        end

        context 'and does not have a specific name' do
          it 'links to the folder with the org in it' do
            user_repo_mkdir("docs-org-name-ruff")
            FileUtils.mkdir_p("/destination")

            out = StringIO.new
            cloner = LocalFilesystemCloner.new({out: out}, fs, user_repo_dir)

            result = cloner.call(source_repo_name: "org-name/docs",
                                 source_ref: "ruff",
                                 destination_parent_dir: "/destination",
                                 destination_dir_name: "reps")

            expect(fs.file_exist?(result.path)).to be true
            expect(out.string).to match(%r{ copying\s*/my/repo/dir/docs-org-name-ruff})
          end
        end

        it 'gives priority to ref/org directory names' do
          user_repo_mkdir("repo-sm")
          user_repo_mkdir("repo-myorg-ref")


          FileUtils.mkdir_p("/destination")

          out = StringIO.new
          cloner = LocalFilesystemCloner.new({out: out}, fs, user_repo_dir)

          result = cloner.call(source_repo_name: "myorg/repo",
                               source_ref: "ref",
                               destination_parent_dir: "/destination",
                               destination_dir_name: "reps")

          expect(fs.file_exist?(result.path)).to be true
          expect(out.string).to match(%r{ copying\s*/my/repo/dir/repo-myorg-ref})

          user_repo_mkdir("repo-ref")

          result = cloner.call(source_repo_name: "myorg/repo",
                               source_ref: "ref",
                               destination_parent_dir: "/destination",
                               destination_dir_name: "reps")

          expect(out.string).to match(%r{ copying\s*/my/repo/dir/repo-ref})
        end
      end
    end
  end
end
