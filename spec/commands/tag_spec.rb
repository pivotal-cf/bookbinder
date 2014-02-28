require 'spec_helper'

describe Cli::Tag do
  include_context 'tmp_dirs'

  let(:book_sha) { 26.times.map { (65 + rand(26)).chr }.join  }
  let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }
  let(:book_title) { 'fantastic/red-mars' }
  let(:config) do
    {
      'book_repo' => book_title,
      'repos' => []
    }
  end

  before do
    GitClient.any_instance.stub :create_tag!
    @book = double
    @book.stub(:full_name).and_return 'anything'
    @book.stub(:target_ref).and_return 'anything'

    Book.stub(:new).with { |args| args[:full_name].should eq book_title }
      .and_return(@book)

    DocRepo.any_instance.stub(:tag_with)
  end

  it 'should tag the book and its constituents' do
    @book.should_receive(:tag_with).with(desired_tag)
    @book.should_receive(:tag_constituents_with).with(desired_tag)
    Cli::Tag.new(config).run [desired_tag]
  end
end
