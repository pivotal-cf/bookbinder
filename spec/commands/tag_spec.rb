require 'spec_helper'

def arrange_fixture_book_and_constituents
  temp_library = tmp_subdir 'markdown_repos'
  book_dir = File.join temp_library, 'book'

  git_dir = File.join book_dir, '.git'
  FileUtils.mkdir_p git_dir
  File.open(File.join(git_dir, 'config'), 'w') do |config|
    config.puts(<<-GIT)
[remote "origin"]
  url = https://github.com/wow-org/such-book.git
	fetch = +refs/heads/*:refs/remotes/origin/*
    GIT
  end

  FileUtils.cp_r 'spec/fixtures/markdown_repos/.', temp_library
  book_dir
end

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
    Octokit::Client.any_instance.stub(:octocat).and_return 'truthy kitten string'
    Octokit::Client.any_instance.stub(:commits).and_return [OpenStruct.new(sha: 'some-sha')]
    Octokit::Client.any_instance.stub(:create_ref).and_return 'something truthy'
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