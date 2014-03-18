require 'spec_helper'

describe Book do
  include_context 'tmp_dirs'

  let(:constituents) do
    [{"github_repo" => "fantastic/dogs-repo", "directory" => "dogs"}]
  end

  let(:book_name) { 'wow-org/such-book' }

  describe '#tag_constituents_with' do
    let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

    before do
      stub_github_for constituents[0]['github_repo']
    end

    it 'should tag the constituent repos' do
      allow(Book).to receive(:new).with(full_name: book_name, constituent_params: constituents).and_call_original

      constituents.each do |c|
        stub_github_for c['github_repo']
        doc_repo = expect_to_receive_and_return_real_now(Repository, :new, full_name: c['github_repo'])
        expect(doc_repo).to receive(:tag_with).with(desired_tag)
      end

      book = Book.new(full_name: book_name, constituent_params: constituents)
      book.tag_constituents_with(desired_tag)
    end
  end

  describe '.from_remote' do
    let(:temp_workspace) { tmp_subdir('workspace') }
    let(:ref) { 'this-is-a-tag' }
    let(:full_name) { 'foo/book' }

    before { stub_github_for full_name, ref }

    it 'unzips an archive at the given path' do
      Book.from_remote(full_name: 'foo/book', destination_dir: temp_workspace, ref: ref)
      File.exists?(File.join(temp_workspace, 'book', 'config.yml')).should be_true
    end
  end
end
