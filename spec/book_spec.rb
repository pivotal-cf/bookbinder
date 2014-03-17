require 'spec_helper'

describe Book do
  include_context 'tmp_dirs'

  let(:constituents) do
    [{"github_repo" => "fantastic/dogs-repo", "directory" => "dogs"}]
  end

  let(:book_name) { 'wow-org/such-book' }

  describe '#tag_constituents' do
    let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

    before do
      @constituent = double
      DocRepo.stub(:from_remote).and_return @constituent
      @book = Book.new full_name: book_name, constituent_params: constituents
      Book.stub(:new).with(full_name: book_name, constituent_params: constituents).and_return @book
    end

    it 'should tag the constituent repos' do
      @constituent.should_receive(:tag_with).with desired_tag
      @book.tag_constituents_with(desired_tag)
    end
  end


  describe '#short_name' do
    before do
      @constituent = double
      DocRepo.stub(:from_remote).and_return @constituent
      @book = Book.new full_name: book_name, constituent_params: constituents
      Book.stub(:new).with(full_name: book_name, constituent_params: constituents).and_return @book
    end

    it 'should be returned' do
      @book.short_name.should eq(book_name.split('/')[1])
    end
  end

  describe '#copy_from_remote' do
    let(:temp_workspace) { tmp_subdir('workspace') }
    let(:ref) { 'this-is-a-tag' }
    let(:book) { Book.new full_name: 'foo/book', target_ref: ref }

    before { stub_github_for book.full_name, ref }

    it 'unzips an archive at the given path' do
      book.copy_from_remote(temp_workspace)
      File.exists?(File.join(temp_workspace, book.short_name, 'config.yml')).should be_true
    end
  end
end
