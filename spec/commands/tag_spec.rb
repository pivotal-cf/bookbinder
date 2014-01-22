require 'spec_helper'

describe Cli::Tag do
  include_context 'tmp_dirs'

  around do |spec|
    temp_library = tmp_subdir 'markdown_repos'
    book_dir = File.join temp_library, 'book'
    FileUtils.cp_r 'spec/fixtures/markdown_repos/.', temp_library
    FileUtils.cd(book_dir) { spec.run }
  end

  # Repos are copied from fixture data, and may fall out of sync
  let(:repos) { [{"github_repo"=>"fantastic/dogs-repo", "directory"=>"dogs"}, {"github_repo"=>"fantastic/my-docs-repo", "directory"=>"docs"}, {"github_repo"=>"fantastic/my-other-docs-repo", "directory"=>"others"}] }
  let(:book_name) { 'wow-org/such-book' }
  let(:book_sha) { 26.times.map { (65 + rand(26)).chr }.join  }
  let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

  before do
    Octokit::Client.any_instance.stub(:octocat).and_return 'truthy kitten string'
    Octokit::Client.any_instance.stub(:commits).and_return [OpenStruct.new(sha: 'some-sha')]
    Octokit::Client.any_instance.stub(:create_ref).and_return 'something truthy'
    @book = Book.new(full_name: book_name, constituent_params: repos)
    Book.stub(:new).with(full_name: book_name, constituent_params: repos).and_return(@book)
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