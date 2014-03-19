class Repository
  include BookbinderLogger
  include ShellOut

  attr_reader :full_name, :copied_to

  def self.build_from_remote(repo_hash, destination_dir, target_ref)
    full_name       = repo_hash.fetch('github_repo')
    target_ref      = target_ref || repo_hash['sha']
    directory       = repo_hash['directory']

    repository = new(full_name: full_name, target_ref: target_ref, github_token: ENV['GITHUB_API_TOKEN'], directory: directory)
    if destination_dir
      repository.copy_from_remote(destination_dir)
    end

    repository
  end

  def self.build_from_local(repo_hash, local_repo_dir, destination_dir)
    full_name       = repo_hash.fetch('github_repo')
    directory       = repo_hash['directory']

    repository = new(full_name: full_name, directory: directory, local_repo_dir: local_repo_dir)
    repository.copy_from_local(destination_dir) if destination_dir

    repository
  end

  def initialize(full_name: nil, target_ref: nil, github_token: nil, directory: nil, local_repo_dir: nil)
    #TODO better error message
    raise 'No full_name provided ' unless full_name
    @full_name = full_name
    @github = GitClient.get_instance(access_token: github_token || ENV['GITHUB_API_TOKEN'])
    @target_ref = target_ref
    @directory = directory
    @local_repo_dir = local_repo_dir
  end

  def tag_with(tagname)
    @github.create_tag! full_name, tagname, head_sha
  end

  def short_name
    full_name.split('/')[1]
  end

  def head_sha
    @head_sha ||= @github.head_sha(full_name)
  end

  def directory
    @directory || short_name
  end

  def copy_from_remote(destination_dir)
    output_dir    = Dir.mktmpdir
    archive       = download_archive
    tarball_path  = File.join(output_dir, "#{short_name}.tar.gz")
    File.open(tarball_path, 'wb') { |f| f.write(archive) }

    directory_listing_before = Dir.entries output_dir
    shell_out "tar xzf #{tarball_path} -C #{output_dir}"
    directory_listing_after = Dir.entries output_dir

    from = File.join output_dir, (directory_listing_after - directory_listing_before).first
    FileUtils.mv from, File.join(destination_dir, directory)

    @copied_to = File.join(destination_dir, directory)
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

  def copied?
    !@copied_to.nil?
  end

  def has_tag?(tagname)
    tags.any? { |tag| tag.name == tagname }
  end

  def update_local_copy
    if File.exist?(path_to_local_repo)
      log 'Updating ' + path_to_local_repo.cyan
      Kernel.system("cd #{path_to_local_repo} && git pull")
    else
      announce_skip
    end
  end

  def announce_skip
    log '  skipping (not found) '.magenta + path_to_local_repo
  end

  def download_archive
    log '  downloading '.yellow + archive_link.blue
    response = Faraday.new.get(archive_link)
    raise "Unable to download repository #{@full_name}: server response #{response.status}" unless response.status == 200
    response.body
  end

  private

  def target_ref
    @target_ref ||= 'master'
  end

  def path_to_local_repo
    File.join(@local_repo_dir, short_name)
  end

  def archive_link
    @archive_link ||= @github.archive_link full_name, ref: target_ref
  end

  def tags
    @github.tags @full_name
  end
end
