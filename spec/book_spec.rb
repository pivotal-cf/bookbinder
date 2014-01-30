require 'spec_helper'

describe Book do
  let(:constituents) do
    [{"github_repo" => "fantastic/dogs-repo", "directory" => "dogs"}]
  end

  let(:book_name) { 'wow-org/such-book' }

  before do
    @constituent = double
    DocRepo.stub(:from_remote).and_return @constituent
    @book = Book.new full_name: book_name, constituent_params: constituents
    Book.stub(:new).with(full_name: book_name, constituent_params: constituents).and_return @book
  end

  describe '#tag_constituents' do
    let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

    it 'should tag the constituent repos' do
      @constituent.should_receive(:tag_with).with desired_tag
      @book.tag_constituents_with(desired_tag)
    end
  end

  describe '#short_name' do
    it 'should be returned' do
      @book.short_name.should eq(book_name.split('/')[1])
    end
  end
end