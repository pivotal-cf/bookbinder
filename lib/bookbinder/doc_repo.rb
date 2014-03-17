class DocRepo < Repository

  Store = {}

  attr_reader :copied_to

  def self.get_instance(full_name, local_repo_dir=nil)
    Store.fetch([full_name, local_repo_dir]) { acquire(full_name, local_repo_dir) }
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
    @local_repo_dir = local_repo_dir
    @subnav_template = repo_hash['subnav_template']

    directory = repo_hash['directory']
    full_name = repo_hash.fetch('github_repo')
    target_ref = target_ref || repo_hash['sha']
    super(full_name: full_name, target_ref: target_ref, github_token: github_token, directory: directory)
  end

  def subnav_template
    return unless @subnav_template
    @subnav_template.gsub(/^_/, '').gsub(/\.erb$/, '')
  end

  def copied?
    !@copied_to.nil?
  end

  def has_tag?(tagname)
    tags.any? { |tag| tag.name == tagname }
  end

  def copy_from_local(destination_dir)
    if File.exist?(path_to_local_repo)
      log '  copying '.yellow + path_to_local_repo
      FileUtils.cp_r path_to_local_repo, File.join(destination_dir, directory)
      @copied_to = File.join(destination_dir, directory)
    else
      announce_skip
    end
  end

  private

  def path_to_local_repo
    File.join(@local_repo_dir, short_name)
  end

  def announce_skip
    log '  skipping (not found) '.magenta + path_to_local_repo
  end

  def self.acquire(full_name, local_repo_dir)
    BookbinderLogger.log "Excerpting #{full_name.cyan}"
    repo = local_repo_dir ? copy(full_name, local_repo_dir) : download(full_name)
    keep(repo, local_repo_dir) if repo
  end

  def self.keep(repo, local_repo_dir)
    Store[[repo.full_name, local_repo_dir]] = repo
  end

  def self.download(full_name)
    from_remote({repo_hash: {'github_repo' => full_name}, destination_dir: Dir.mktmpdir})
  end

  def self.copy(full_name, local_repo_dir)
    from_local(repo_hash: {'github_repo' => full_name}, local_dir: local_repo_dir, destination_dir: Dir.mktmpdir)
  end
end
