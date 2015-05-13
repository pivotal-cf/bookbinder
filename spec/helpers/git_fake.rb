module Bookbinder
  class GitFake
    def initialize
      @git_urls = []
    end

    def clone(url, name, path: nil, checkout: 'master')
      local_repo_dir = File.expand_path('../../fixtures/repositories', __FILE__)
      destination = File.join("#{path}", name)

      FileUtils.mkdir_p(destination)
      FileUtils.cp_r(File.join(local_repo_dir, File.basename(url), '.'), destination)

      @git_urls << url

      if checkout && checkout != 'master'
        Repo.new(url, destination).tap do |g|
          g.checkout(checkout)
        end
      else
        Repo.new(url, destination)
      end
    end

    def update(url)
      # no-op
    end

    def read_file(filename, from_repo: nil, checkout: 'master')
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        clone(from_repo, "read-file", path: path, checkout: checkout)
        path.join("read-file", filename).read
      end
    end

    def received_clone_with_urls(git_urls)
      @git_urls == git_urls
    end

    def reset_fake
      @git_urls = []
    end

    class Repo
      def initialize(repository, path)
        @repository = repository
        @path = path
      end

      def checkout(ref)
        @ref = ref
        local_repo_dir = File.expand_path('../../fixtures/repositories', __FILE__)
        # To simulate a git checkout, remove everything first instead of copying over the top.
        FileUtils.rm_rf(Dir.glob("#{@path}/*"))
        FileUtils.cp_r(File.join(local_repo_dir, "#{File.basename(@repository)}-ref-#{ref}", '.'), @path)
      end
    end
  end
end
