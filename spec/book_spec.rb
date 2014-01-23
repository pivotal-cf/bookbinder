require 'spec_helper'

describe Book do
  let(:repos) do
    [{"github_repo" => "fantastic/dogs-repo", "directory" => "dogs"},
     {"github_repo" => "fantastic/my-docs-repo", "directory" => "docs"},
     {"github_repo" => "fantastic/my-other-docs-repo", "directory" => "others"}]
  end
  let(:book_name) { 'wow-org/such-book' }

  before do
    @constituent = double
    DocRepo.stub(:from_remote).and_return(@constituent)
    Octokit::Client.any_instance.stub(:octocat).and_return 'truthy kitten string'
    @book = Book.new(full_name: book_name, constituent_params: repos)
    Octokit::Client.any_instance.stub(:commits).and_return [OpenStruct.new(sha: 'some-sha')]
    Octokit::Client.any_instance.stub(:create_ref).and_return 'something truthy'
    Book.stub(:new).with(full_name: book_name, constituent_params: repos).and_return(@book)
  end

  describe '#tag_constituents' do
    let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join  }

    it 'should tag the constituent repos' do
      @constituent.should_receive(:tag_with).with(desired_tag).at_least(1).times
      @book.tag_constituents_with(desired_tag)
    end
  end

  describe '#short_name' do
    it 'should be returned' do
      @book.short_name.should eq(book_name.split('/')[1])
    end
  end
end