require 'pathname'
require 'tmpdir'
require_relative '../../../../lib/bookbinder/ingest/git_accessor'
require_relative '../../../helpers/git_repo'
require_relative '../../../helpers/redirection'

module Bookbinder
  module Ingest
    describe GitAccessor do
      include GitRepo
      include Redirection

      it "clones to a given dir" do
        Dir.mktmpdir do |dir|
          init_repo(at_dir: "#{dir}/srcgorepo",
                    file: 'foo',
                    contents: 'bar',
                    commit_message: 'baz')
          GitAccessor.new.clone("#{dir}/srcgorepo", 'destgorepo', path: dir)
          expect(Pathname("#{dir}/destgorepo/foo").read).to eq("bar\n")
        end
      end

      it "only clones once for a given set of params for a single GitAccessor instance" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'Gemfile',
                    contents: 'gemstuffz',
                    commit_message: 'new railz plz')

          git = GitAccessor.new

          git.clone(path.join('srcrepo'), 'destrepo', path: path)
          expect { git.clone(path.join('srcrepo'), 'destrepo', path: path) }.
            not_to change { path.join('destrepo', 'Gemfile').mtime }
        end
      end

      it "only clones once for a given set of params for multiple GitAccessor instances" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'Gemfile',
                    contents: 'gemstuffz',
                    commit_message: 'new railz plz')

          first_git = GitAccessor.new
          second_git = GitAccessor.new

          first_git.clone(path.join('srcrepo'), 'destrepo', path: path)
          expect { second_git.clone(path.join('srcrepo'), 'destrepo', path: path) }.
            not_to change { path.join('destrepo', 'Gemfile').mtime }
        end
      end

      it "can clone and checkout in one call" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(branch: 'mybranch',
                    at_dir: path.join('srcgorepo'),
                    file: 'foo',
                    contents: 'bar',
                    commit_message: 'baz')
          GitAccessor.new.clone(path.join("srcgorepo"), 'destgorepo',
                                checkout: 'mybranch',
                                path: path)
          expect(path.join('destgorepo', 'foo').read).to eq("bar\n")
        end
      end

      it "can checkout different branches of the same cached repo" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'Gemfile',
                    contents: 'gemstuffz',
                    commit_message: 'new railz plz',
                    branch: 'newbranch')

          git = GitAccessor.new

          git.clone(path.join('srcrepo'), 'destrepo', path: path, checkout: 'newbranch')
          expect(path.join('destrepo/Gemfile')).to exist
          git.clone(path.join('srcrepo'), 'destrepo', path: path, checkout: 'master')
          expect(path.join('destrepo/Gemfile')).not_to exist
        end
      end

      it "can return the contents of a file in one step, using its own temp directory" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'Gemfile',
                    contents: 'gemstuffz',
                    commit_message: 'new railz plz',
                    branch: 'newbranch')

          git = GitAccessor.new

          expect(
            git.read_file(
              "Gemfile",
              from_repo: path.join('srcrepo'),
              checkout: 'newbranch'
            )
          ).to eq("gemstuffz\n")
        end
      end

      it "can access the last commit date of a given file in an existing repo" do
        require 'time'
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          original_date = ENV['GIT_AUTHOR_DATE']

          begin
            date = Time.new(2003, 1, 2)
            ENV['GIT_AUTHOR_DATE'] = date.iso8601

            init_repo(at_dir: path.join('source', 'section-repo'),
                      file: 'some-dir/Gemfile',
                      contents: 'gemstuffz',
                      commit_message: 'new railz plz')

            git = GitAccessor.new

            expect(
              git.author_date(path.join('source', 'section-repo', 'some-dir', 'Gemfile'))
            ).to eq(date)
          ensure
            ENV['GIT_AUTHOR_DATE'] = original_date
          end
        end
      end

      it "returns nil if a given file is not checked into version control" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)

          FileUtils.mkdir(path.join('section-dir'))
          File.open(path.join('section-dir', 'Gemfile'), "a") do |io|
            io.write('bookbindery')
          end

          git = GitAccessor.new

          expect(
            git.author_date(path.join('section-dir', 'Gemfile'))
          ).to be_nil
        end
      end

      it "can update a previous clone" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'foo',
                    contents: 'bar',
                    commit_message: 'baz')
          git = GitAccessor.new
          git.clone(path.join("srcrepo"), 'destrepo', path: path)
          swallow_stderr do
            system("cd #{path.join('srcrepo')}; touch newfile; git add .; git commit -q -m foo")
          end
          result = git.update(path.join('destrepo'))
          expect(result).to be_success
          expect(path.join('destrepo', 'newfile')).to exist
        end
      end

      it "returns an error if update is for non-existent repo" do
        update = GitAccessor.new.update("someplacethatdoesntexistyo")
        expect(update).not_to be_success
        expect(update.reason).to match(/not found/)
      end

      it "returns an error if update causes merge overwrite error" do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          init_repo(at_dir: path.join('srcrepo'),
                    file: 'foo',
                    contents: 'bar',
                    commit_message: 'baz')
          git = GitAccessor.new
          git.clone(path.join("srcrepo"), 'destrepo', path: path)
          swallow_stderr do
            system("cd #{path.join('srcrepo')}; touch newfile; git add .; git commit -q -m foo")
          end
          system("cd #{path.join('destrepo')}; touch newfile")
          result = git.update(path.join('destrepo'))
          expect(result).not_to be_success
          expect(result.reason).to match(/merge error/)
        end
      end

      describe 'remote_tagging' do
        it "can tag and push in one step" do
          Dir.mktmpdir do |dir|
            path = Pathname(dir)
            init_repo(branch: 'branchiwanttotag',
              at_dir: path.join('srcrepo'),
              file: 'foo',
              contents: 'bar',
              commit_message: 'baz')
            git = GitAccessor.new
            git.remote_tag(path.join("srcrepo"), 'mytagname', 'branchiwanttotag')
            git.clone(path.join("srcrepo"), "destrepo", path: path)

            tags = `cd #{path.join('destrepo')}; git tag`.split("\n")

            expect(tags).to eq(["mytagname"])
          end
        end

        it "raises an exception if tag exists" do
          Dir.mktmpdir do |dir|
            path = Pathname(dir)
            init_repo(branch: 'branchiwanttotag',
              at_dir: path.join('srcrepo'),
              file: 'foo',
              contents: 'bar',
              commit_message: 'baz')
            git = GitAccessor.new
            git.remote_tag(path.join("srcrepo"), 'mytagname', 'branchiwanttotag')

            expect { git.remote_tag(path.join("srcrepo"), 'mytagname', 'branchiwanttotag') }.
              to raise_error(GitAccessor::TagExists)
          end
        end

        it "raises an exception if tag ref is invalid" do
          Dir.mktmpdir do |dir|
            path = Pathname(dir)
            init_repo(branch: 'branchiwanttotag',
              at_dir: path.join('srcrepo'),
              file: 'foo',
              contents: 'bar',
              commit_message: 'baz')
            git = GitAccessor.new

            expect { git.remote_tag(path.join("srcrepo"), 'mytagname', 'nonexistent') }.
              to raise_error(GitAccessor::InvalidTagRef)
          end
        end
      end
    end
  end
end
