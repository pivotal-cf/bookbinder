class DocRepo < Repository
  def self.store
    @@store ||= {}
  end

  attr_reader :copied_to

  def self.get_instance(repo_hash: {}, local_repo_dir: nil, destination_dir: nil, target_tag: nil)
    destination_dir ||= Dir.mktmpdir
    store.fetch([repo_hash['github_repo'], local_repo_dir]) { acquire(repo_hash, local_repo_dir, destination_dir, target_tag) }
  end

  def initialize(repo_hash, github_token, local_repo_dir, target_ref)
    @subnav_template = repo_hash['subnav_template']

    local_repo_dir = local_repo_dir
    directory = repo_hash['directory']
    full_name = repo_hash.fetch('github_repo')
    target_ref = target_ref || repo_hash['sha']
    super(full_name: full_name, target_ref: target_ref, github_token: github_token, directory: directory, local_repo_dir: local_repo_dir)
  end

  def subnav_template
    @subnav_template.gsub(/^_/, '').gsub(/\.erb$/, '') if @subnav_template
  end

  private

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

  def self.download(repo_hash, destination, target_tag)
    from_remote(repo_hash: repo_hash, destination_dir: destination, target_tag: target_tag)
  end
  private_class_method :download

  def self.copy(repo_hash, local_repo_dir, destination)
    from_local(repo_hash: repo_hash, local_repo_dir: local_repo_dir, destination_dir: destination)
  end
  private_class_method :copy

  def self.from_remote(repo_hash: {}, github_token: ENV['GITHUB_API_TOKEN'], destination_dir: nil, target_tag: nil)
    repo = self.new(repo_hash, github_token, nil, target_tag)
    repo.copy_from_remote(destination_dir) if destination_dir
    repo
  end
  private_class_method :from_remote

  def self.from_local(repo_hash: {}, local_repo_dir: '', destination_dir: nil)
    repo = self.new(repo_hash, nil, local_repo_dir, nil)
    repo.copy_from_local(destination_dir) if destination_dir
    repo
  end
  private_class_method :from_local
end
