module Bookbinder
  class Github
    def initialize
      @git_urls = []
    end

    def clone(url, name, path: nil)
      FileUtils.cp_r File.join(Bookbinder::RepoFixture.repos_dir, name), File.join(Dir.pwd, 'output/dita/dita_sections')

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