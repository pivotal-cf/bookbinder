require_relative "../../../lib/bookbinder/directory_helpers"
require_relative "../../../lib/bookbinder/book"
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/nil_logger'

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
    let(:book) { Book.new(full_name: 'myorg/test') }
    let(:repo) { double(GitHubRepository) }

    it "has a full name" do
      expect(book.full_name).to eq('myorg/test')
    end

    describe '#tag_self_and_sections_with' do
      let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join }

      it 'should tag itself and the repos for each section' do
        sections.each do |s|
          doc_repo = double
          expect(GitHubRepository).to receive(:new).with(
            logger: logger,
            full_name: s['repository']['name'],
          ).and_return(doc_repo)
          expect(doc_repo).to receive(:tag_with).with(desired_tag)
        end

        self_repo = double
        expect(GitHubRepository).to receive(:new).with(
          logger: logger,
          full_name: book_name,
          github_token: nil,
        ).and_return(self_repo)
        expect(self_repo).to receive(:tag_with).with(desired_tag)

        book = Book.new(logger: logger, full_name: book_name, sections: sections)
        book.tag_self_and_sections_with(desired_tag)
      end
    end
  end
end
