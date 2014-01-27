require 'spec_helper'

describe '$ bookbinder' do
  include_context 'tmp_dirs'

  around do |spec|
    book_dir = arrange_fixture_book_and_constituents
    FileUtils.cd(book_dir) { spec.run }
  end

  describe 'publish' do
    describe 'local' do
      it 'generates a sinatra app' do
        `#{GEM_ROOT}/bin/bookbinder publish local`

        index_html = File.read File.join('final_app', 'public', 'foods', 'sweet','index.html')
        index_html.should include 'This is a Markdown Page'
      end

      it 'respects subnav includes' do
        `#{GEM_ROOT}/bin/bookbinder publish local`

        dogs_index = File.read File.join('final_app', 'public', 'dogs', 'index.html')
        dogs_index.should include 'Woof'
        dogs_index.should_not include 'Cabbage'
        dogs_index.should_not include 'Sputnik'
        dogs_index.should_not include 'Cherry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'savory', 'index.html')
        papers_index.should include 'Cabbage'
        papers_index.should_not include 'Sputnik'
        papers_index.should_not include 'Woof'
        papers_index.should_not include 'Strawberry'

        papers_index = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
        papers_index.should include 'Strawberry'
        papers_index.should_not include 'Sputnik'
        papers_index.should_not include 'Woof'
        papers_index.should_not include 'Spinach'
      end

      it 'creates a PDF file'
    end

    describe 'github' do
      xit 'generates a sinatra app' do
        `#{GEM_ROOT}/bin/bookbinder publish github`

        index_html = File.read File.join('final_app', 'public', 'papers', 'index.html')
        index_html.should include 'This is a Markdown Page'
      end

      context 'when no config.yml credentials are provided' do
        it 'generates a sinatra app'
      end
    end
  end

  describe 'tag' do
    let(:desired_tag) { '1.1.0.0' }
    let(:config_repos) do
      [
        {'github_repo' => 'foo/dogs-repo', 'directory' => 'temporarily-dogs'},
        {'github_repo' => 'baz/my-docs-repo', 'directory' => 'docs-for-now'}
      ]
    end
    let(:tags) {[]}

    before do
      ENV.stub(:[])
      ENV.stub(:[]).with('GITHUB_API_TOKEN').and_return('alkaline')

      Octokit::Client.any_instance.stub(:octocat).and_return('Kittens are truthy')
      Octokit::Client.any_instance.stub(:tags).and_return(tags)
    end

    xit 'should tag all the repos with the given tag' do
      repos = config_repos.map {|repo_data| DocRepo.new(repo_data, 'foo', nil ,nil) }
      repos.each { |repo| repo.should_not have_tag(desired_tag) }

      `#{GEM_ROOT}/bin/bookbinder tag #{desired_tag}`

      repos.each { |repo| repo.should have_tag(desired_tag) }
    end
  end
end