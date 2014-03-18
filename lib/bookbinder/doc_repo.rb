class DocRepo
  def self.store
    @@store ||= {}
  end

  def self.get_instance(repo_hash: {}, local_repo_dir: nil, destination_dir: nil, target_tag: nil)
    destination_dir ||= Dir.mktmpdir
    store.fetch([repo_hash['github_repo'], local_repo_dir]) { acquire(repo_hash, local_repo_dir, destination_dir, target_tag) }
  end

  def initialize(repository, subnav_template)
    @subnav_template = subnav_template
    @repository = repository
  end

  def subnav_template
    @subnav_template.gsub(/^_/, '').gsub(/\.erb$/, '') if @subnav_template
  end

  def directory
    @repository.directory
  end

  def full_name
    @repository.full_name
  end

  def copied?
    @repository.copied?
  end

  private

  def self.announce_skip(repository)
    BookbinderLogger.log '  skipping (not found) '.magenta + repository.path_to_local_repo
  end

  def self.acquire(repo_hash, local_repo_dir, destination, target_tag)
    BookbinderLogger.log "Excerpting #{repo_hash.fetch('github_repo').cyan}"
    repo = local_repo_dir ? copy(repo_hash, local_repo_dir, destination) : download(repo_hash, destination, target_tag)
    keep(repo, local_repo_dir) if repo
  end
  private_class_method :acquire

  def self.keep(repo, local_repo_dir)
    store[[repo.full_name, local_repo_dir]] = repo
  end
  private_class_method :keep

  def self.download(repo_hash, destination_dir, target_ref)
    full_name       = repo_hash.fetch('github_repo')
    target_ref      = target_ref || repo_hash['sha']
    directory       = repo_hash['directory']

    repository = Repository.new(full_name: full_name, target_ref: target_ref, github_token: ENV['GITHUB_API_TOKEN'], directory: directory)
    if destination_dir
      repository.copy_from_remote(destination_dir) or announce_skip(repository)
    end

    subnav_template = repo_hash['subnav_template']

    self.new(repository, subnav_template)
  end
  private_class_method :download

  def self.copy(repo_hash, local_repo_dir, destination_dir)
    full_name       = repo_hash.fetch('github_repo')
    directory       = repo_hash['directory']

    repository = Repository.new(full_name: full_name, directory: directory, local_repo_dir: local_repo_dir)
    if destination_dir
      repository.copy_from_local(destination_dir) or announce_skip(repository)
    end

    self.new(repository, repo_hash['subnav_template'])
  end
  private_class_method :copy
end
