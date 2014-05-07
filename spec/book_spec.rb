require 'spec_helper'

module Bookbinder
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

    describe '#tag_self_and_sections_with' do
      let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join }

      it 'should tag itself and the repos for each section' do
        sections.each do |s|
          doc_repo = double
          expect(Repository).to receive(:new).with(logger: logger, full_name: s['repository']['name']).and_return(doc_repo)
          expect(doc_repo).to receive(:tag_with).with(desired_tag)
        end

        self_repo = double
        expect(Repository).to receive(:new).with(logger: logger, full_name: book_name, target_ref: nil, github_token: nil).and_return(self_repo)
        expect(self_repo).to receive(:tag_with).with(desired_tag)

        book = Book.new(logger: logger, full_name: book_name, sections: sections)
        book.tag_self_and_sections_with(desired_tag)
      end
    end

    describe '.from_remote' do
      let(:temp_workspace) { tmp_subdir('workspace') }
      let(:ref) { 'this-is-a-tag' }
      let(:full_name) { 'foo/book' }
      let(:git_client) { GitClient.new(logger) }

      before do
        stub_github_for git_client, full_name, ref
        allow(GitClient).to receive(:new).and_return git_client
      end

      it 'unzips an archive at the given path' do
        Book.from_remote(logger: logger, full_name: 'foo/book', destination_dir: temp_workspace, ref: ref)
        File.exists?(File.join(temp_workspace, 'book', 'config.yml')).should be_true
      end
    end
  end
end