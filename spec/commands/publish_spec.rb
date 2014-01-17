require 'spec_helper'

describe Cli::Publish do
  include_context 'tmp_dirs'
  around do |spec|
    book_dir = 'spec/fixtures/markdown_repos/book'
    Dir.chdir(book_dir) { spec.run }
    FileUtils.rm_rf File.join book_dir, 'final_app'
    FileUtils.rm_rf File.join book_dir, 'output'
  end

  context 'local' do
    it 'creates some static HTML' do
      Cli::Publish.new.run ['local']

      index_html = File.read File.join('final_app', 'public', 'docs', 'index.html')
      index_html.should include 'This is a Markdown Page'
    end
  end

  context 'github' do
    xit 'creates some static HTML' do
      Cli::Publish.new.run ['github']

      index_html = File.read File.join('final_app', 'public', 'docs', 'index.html')
      index_html.should include 'This is a Markdown Page'
    end
  end
end