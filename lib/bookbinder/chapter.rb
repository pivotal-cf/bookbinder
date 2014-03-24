class Chapter
  def self.store
    @@store ||= {}
  end

  def self.get_instance(section_hash: {}, local_repo_dir: nil, destination_dir: nil, target_tag: nil)
    destination_dir ||= Dir.mktmpdir
    store.fetch([section_hash.fetch('repository', {})['name'], local_repo_dir]) { acquire(section_hash, local_repo_dir, destination_dir, target_tag) }
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

  def self.acquire(section_hash, local_repo_dir, destination, target_tag)
    BookbinderLogger.log 'Gathering ' + section_hash.fetch('repository', {})['name'].cyan
    repository = build_repository(destination, local_repo_dir, section_hash, target_tag)
    chapter = new(repository, section_hash['subnav_template'])

    keep(chapter, local_repo_dir) if chapter
  end
  private_class_method :acquire

  def self.build_repository(destination, local_repo_dir, repo_hash, target_tag)
    if local_repo_dir
      Repository.build_from_local(repo_hash, local_repo_dir, destination)
    else
      Repository.build_from_remote(repo_hash, destination, target_tag)
    end
  end
  private_class_method :build_repository

  def self.keep(repo, local_repo_dir)
    store[[repo.full_name, local_repo_dir]] = repo
  end
  private_class_method :keep
end
