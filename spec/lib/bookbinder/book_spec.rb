require_relative "../../../lib/bookbinder/directory_helpers"
require_relative "../../../lib/bookbinder/book"
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/nil_logger'

module Bookbinder
  include Bookbinder::DirectoryHelperMethods
  describe Book do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:sections) do
      [{
           'repository' => {
               'name' => 'fantastic/dogs-repo'
           },
           'directory' => 'dogs'
       }]
    end

    let(:book_name) { 'wow-org/such-book' }
    let(:book) { Book.new(full_name: 'test') }
    let(:repo) { double(GitHubRepository) }

    describe '#tag_self_and_sections_with' do
      let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join }

      it 'should tag itself and the repos for each section' do
        sections.each do |s|
          doc_repo = double
          expect(GitHubRepository).to receive(:new).with(logger: logger, full_name: s['repository']['name']).and_return(doc_repo)
          expect(doc_repo).to receive(:tag_with).with(desired_tag)
        end

        self_repo = double
        expect(GitHubRepository).to receive(:new).with(logger: logger, full_name: book_name, target_ref: nil, github_token: nil).and_return(self_repo)
        expect(self_repo).to receive(:tag_with).with(desired_tag)

        book = Book.new(logger: logger, full_name: book_name, sections: sections)
        book.tag_self_and_sections_with(desired_tag)
      end
    end

    describe '#full_name' do
      it 'returns the name of the repository' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        expect(repo).to receive(:full_name).and_return('test')
        expect(book.full_name).to eq('test')
      end
    end

    describe '#head_sha' do
      it 'returns the sha of the latest commit' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        expect(repo).to receive(:head_sha).and_return('latest-sha')
        expect(book.head_sha).to eq('latest-sha')
      end
    end

    describe '#directory' do
      it 'returns the directory of the repository' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        expect(repo).to receive(:directory).and_return('test-dir')
        expect(book.directory).to eq('test-dir')
      end
    end

    describe '#copy_from_remote' do
      let(:destination_dir) { 'some-path' }
      let(:git_accessor) { double(Git) }
      it 'copies the repository from the remote directory' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        expect(repo).to receive(:copy_from_remote).with(destination_dir, Git).and_return(destination_dir)
        expect(book.copy_from_remote(destination_dir)).to eq(destination_dir)
      end
    end

    describe '#get_modification_date_for' do
      let(:full_file_path) { '/some/dir/galaxy-book/output/master_middleman/source/404.html.md'}
      let(:git_log_time_for_file) { Time.new(3028, 1, 19) }
      let(:git_base_object) { double Git::Base }

      it 'returns the last modified date for the specified file' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        allow(Git).to receive(:open).with('/some/dir/galaxy-book/').and_return(git_base_object)

        expect(repo).to receive(:get_modification_date_for).
                            with(file: 'master_middleman/source/404.html.md',git: git_base_object).
                            and_return(git_log_time_for_file)
        expect(book.get_modification_date_for(full_path: full_file_path)).to eq(git_log_time_for_file)
      end

      it 'raises if the git directory is invalid' do
        allow(GitHubRepository).to receive(:new).with(logger: nil, full_name: 'test', target_ref: nil, github_token: nil).and_return(repo)
        allow(Git).to receive(:open).with('/some/dir/galaxy-book/').and_raise(ArgumentError)

        expect{ book.get_modification_date_for(full_path: full_file_path) }.to raise_error(/Invalid git repository/)
      end
    end

    describe '.from_remote' do
      let(:temp_workspace) { tmp_subdir('workspace') }
      let(:ref) { 'this-is-a-tag' }
      let(:full_name) { 'foo/book' }
      let(:destination_dir) { 'some-path' }
      let(:new_book) { double(Book) }

      it 'creates a new Book' do
        expect(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: Git)
                        .and_return(new_book)
        allow(new_book).to receive(:copy_from_remote)
        Book.from_remote(logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref)
      end

      context 'when the destination dir is set' do
        it 'copies the book from remote' do
          allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: Git)
                         .and_return(new_book)
          expect(new_book).to receive(:copy_from_remote).with(destination_dir)
          Book.from_remote(
              logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref)
        end
      end

      context 'when the destination dir is not set' do
        it 'copies the book from remote' do
          allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: Git)
                         .and_return(new_book)
          expect(new_book).to_not receive(:copy_from_remote)
          Book.from_remote(
              logger: logger, full_name: full_name, ref: ref)
        end
      end

      it 'returns the book' do
        allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: Git)
                        .and_return(new_book)
        allow(new_book).to receive(:copy_from_remote)
        expect(Book.from_remote(logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref)).to eq(new_book)
      end
    end


  end
end
