class DocRepo < Repository

  Store = {}

  attr_reader :copied_to

  def self.get_instance(repo_hash, local_repo_dir=nil)
    Store.fetch([repo_hash['github_repo'], local_repo_dir]) { acquire(repo_hash, local_repo_dir) }
  end

  def self.from_remote(repo_hash: {}, github_token: ENV['GITHUB_API_TOKEN'], destination_dir: nil, target_tag: nil)
    repo = self.new(repo_hash, github_token, nil, target_tag)
    repo.copy_from_remote(destination_dir) if destination_dir
    repo
  end

  def self.from_local(repo_hash: {}, local_dir: '', destination_dir: nil)
    repo = self.new(repo_hash, nil, local_dir, nil)
    repo.copy_from_local(destination_dir) if destination_dir
    repo
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
    return unless @subnav_template
    @subnav_template.gsub(/^_/, '').gsub(/\.erb$/, '')
  end

  private

  def self.acquire(repo_hash, local_repo_dir)
    BookbinderLogger.log "Excerpting #{repo_hash.fetch('github_repo').cyan}"
    repo = local_repo_dir ? copy(repo_hash, local_repo_dir) : download(repo_hash)
    keep(repo, local_repo_dir) if repo
  end

  def self.keep(repo, local_repo_dir)
    Store[[repo.full_name, local_repo_dir]] = repo
  end

  def self.download(repo_hash)
    from_remote({repo_hash: repo_hash, destination_dir: Dir.mktmpdir})
  end

  def self.copy(repo_hash, local_repo_dir)
    from_local(repo_hash: repo_hash, local_dir: local_repo_dir, destination_dir: Dir.mktmpdir)
  end
end
