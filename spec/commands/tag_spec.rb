require 'spec_helper'

describe Cli::Tag do
  include_context 'tmp_dirs'

  around do |spec|
    book_dir = arrange_fixture_book_and_constituents
    FileUtils.cd(book_dir) { spec.run }
  end

  let(:book_name) { 'wow-org/such-book' }
  let(:book_sha) { 26.times.map { (65 + rand(26)).chr }.join  }
  let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

  before do
    GitClient.any_instance.stub :create_tag!
    @book = Book.new(full_name: book_name)
    Book.stub(:new).with { |args| args[:full_name].should eq book_name }.and_return(@book)
    DocRepo.any_instance.stub(:tag_with)
  end

  it 'should tag the book' do
    @book.should_receive(:tag_with).with(desired_tag)
    Cli::Tag.new.run [desired_tag]
  end

  it 'should tag the constituent repos' do
    @book.should_receive(:tag_constituents_with).with(desired_tag)
    Cli::Tag.new.run [desired_tag]
  end
end