require 'webmock/rspec'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    directory = File.join(tmpdir, name)
    FileUtils.mkdir directory
    directory
  end

  let(:tmpdir) { Dir.mktmpdir }

  def arrange_fixture_book_and_constituents
    temp_library = tmp_subdir 'markdown_repos'
    FileUtils.cp_r "#{GEM_ROOT}/spec/fixtures/markdown_repos/.", temp_library

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

    book_dir
  end
end

def generate_middleman_with(index_page)
  dir = tmp_subdir 'master_middleman'
  source_dir = File.join(dir, 'source')
  FileUtils.mkdir source_dir
  FileUtils.cp File.join('spec', 'fixtures', index_page), File.join(source_dir, 'index.html.md.erb')
  dir
end

def stub_github_for(repo_name, some_ref='master')
  github = GitClient.get_instance access_token: 'foo'
  zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_ref}.tar.gz"
  github.stub(:archive_link).with(repo_name, ref: some_ref)
    .and_return(zipped_repo_url)

  zipped_repo = MarkdownRepoFixture.tarball repo_name.split('/').last, some_ref
  stub_request(:get, zipped_repo_url).to_return(
      :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
  )
end

def mock_github_for(repo_name, some_ref='master')
  github = GitClient.get_instance access_token: 'foo'
  zipped_repo_url = "https://github.com/#{repo_name}/archive/#{some_ref}.tar.gz"
  github.should_receive(:archive_link).with(repo_name, ref: some_ref)
    .once
    .and_return(zipped_repo_url)

  zipped_repo = MarkdownRepoFixture.tarball repo_name.split('/').last, some_ref
  stub_request(:get, zipped_repo_url).to_return(
      :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
  )
end

require_relative '../lib/bookbinder'
require_relative '../template_app/app.rb'
require_relative 'fixtures/markdown_repo_fixture'

#GEM_ROOT = Dir.pwd

RSpec.configure do |config|
  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil

    #the Github API token must be in the ENV or tests will fail.
    ENV['GITHUB_API_TOKEN'] = 'foo'
  end

  config.before do
    BookbinderLogger.stub(:log) {  }
    Pusher.any_instance.stub(:push)
  end

  module SpecHelperMethods
    def squelch_middleman_output
      Thor::Shell::Basic.any_instance.stub(:say_status) {}
      Middleman::Logger.any_instance.stub(:add) {}
    end

    def write_markdown_source_file(path_under_source_dir, title, content = nil, breadcrumb_title = nil)
      full_path = File.join(source_dir, path_under_source_dir)
      full_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p full_pathname.dirname
      breadcrumb_code = breadcrumb_title ? "breadcrumb: #{breadcrumb_title}\n" : ''
      final_content = "---\ntitle: #{title}\n#{breadcrumb_code}---\n#{content}"
      File.open(full_path, 'w') { |f| f.write(final_content) }
    end

    def run_middleman(template_variables = {})
      MiddlemanRunner.new.run tmpdir, template_variables
    end
  end

  config.include SpecHelperMethods
end

