require 'spec_helper'

describe Cli::Publish do
  include_context 'tmp_dirs'
  around do |spec|
    temp_library = tmp_subdir 'markdown_repos'
    book_dir = File.join temp_library, 'book'
    FileUtils.cp_r 'spec/fixtures/markdown_repos/.', temp_library
    FileUtils.cd(book_dir) { spec.run }
  end

  context 'local' do
    it 'creates some static HTML' do
      Cli::Publish.new.run ['local']

      index_html = File.read File.join('final_app', 'public', 'docs', 'index.html')
      index_html.should include 'This is a Markdown Page'
    end
  end

  context 'github' do
    before do
      Octokit::Client.any_instance.stub(:octocat).and_return 'ascii kitten proves auth validity'
      stub_github_for 'fantastic/dogs-repo', 'dog-sha'
      stub_github_for 'fantastic/my-docs-repo', 'my-docs-sha'
      stub_github_for 'fantastic/my-other-docs-repo', 'my-other-sha'
    end

    it 'creates some static HTML' do
      Cli::Publish.new.run ['github']

      index_html = File.read File.join('final_app', 'public', 'docs', 'index.html')
      index_html.should include 'This is a Markdown Page'
    end
  end
end