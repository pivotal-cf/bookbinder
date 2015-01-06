class SpecGitAccessor
  def self.clone(repository, name, options = {})
    local_repo_dir = File.expand_path('../../fixtures/repositories', __FILE__)
    destination = File.join(options.fetch(:path, ''), name)

    FileUtils.mkdir_p(destination)
    FileUtils.cp_r(File.join(local_repo_dir, File.basename(repository), '.'), destination)
    new(repository, destination)
  end

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

  def log
    SpecGitLog.new(self.clone, @ref)
  end

  def gtree(ref)
    SpecGitGtree.new
  end
end

