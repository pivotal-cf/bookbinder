require 'webmock/rspec'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    directory = File.join(tmpdir, name)
    FileUtils.mkdir directory
    directory
  end

  let(:tmpdir) { Dir.mktmpdir }
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

  zipped_repo = RepoFixture.tarball repo_name.split('/').last, some_ref
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

  zipped_repo = RepoFixture.tarball repo_name.split('/').last, some_ref
  stub_request(:get, zipped_repo_url).to_return(
      :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
  )
end

def around_with_fixture_repo(&block)
  around do |spec|
    temp_library = tmp_subdir 'repositories'
    FileUtils.cp_r File.join(RepoFixture.repos_dir, '.'), temp_library
    FileUtils.cd(File.join(temp_library, 'book')) do
      block.call(spec)
    end
  end
end

def expect_to_receive_and_return_real_now(subject, method, *args)
  real_obj = subject.public_send(method, *args)
  expect(subject).to receive(method).with(*args).and_return(real_obj)
  real_obj
end

require_relative '../lib/bookbinder'
require_relative '../template_app/app.rb'
require_relative 'fixtures/repo_fixture'

RSpec.configure do |config|
  config.before do
    # awful hack to prevent tests that invoke middleman directly from polluting code that shells out to call it
    ENV['MM_ROOT'] = nil

    #the Github API token must be in the ENV or tests will fail.
    ENV['GITHUB_API_TOKEN'] = 'foo'
  end

  config.before do
    BookbinderLogger.stub(:log) {}
    BookbinderLogger.stub(:log_print) {}
    Pusher.any_instance.stub(:push) unless self.class.metadata[:enable_pusher]

    allow(Chapter).to receive(:store).and_return({})
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
  end

  config.include SpecHelperMethods
end

