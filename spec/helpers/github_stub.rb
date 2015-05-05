require_relative '../../lib/bookbinder/local_file_system_accessor'

module Bookbinder
  class GithubStub
    def initialize
      @git_urls = []
    end

    def clone(url, desired_name, path: nil)
      source_dir = url.split('/').last
      source_location = File.join(Bookbinder::RepoFixture.repos_dir, source_dir)
      LocalFileSystemAccessor.new.copy_contents(source_location, File.join(path, desired_name))

      @git_urls << url
    end

    def received_clone_with_urls(git_urls)
      @git_urls == git_urls
    end

    def reset_fake
      @git_urls = []
    end
  end
end