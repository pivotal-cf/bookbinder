class DocRepo

  attr_reader :subnav_template

  include ShellOut
  include BookbinderLogger
  include Repository

  def self.github_master_head_ref_path(full_name)
    "repos/#{full_name}/git/refs/heads/master"
  end

  def self.from_remote(repo_hash: {}, github_token: ENV['GITHUB_API_TOKEN'], destination_dir: nil)
    self.new(repo_hash, github_token, nil, destination_dir)
  end

  def self.from_local(repo_hash: {}, local_dir: '', destination_dir: nil)
    self.new(repo_hash, nil, local_dir, destination_dir)
  end

  def copied?
    @copied
  end

  def directory
    @directory || short_name
  end

  def copy_to(destination_dir)
    if @local_repo_dir.nil?
      copy_from_remote(destination_dir)
    else
      copy_from_local(destination_dir)
    end
  end

  def has_tag?(tagname)
    tags.any? { |tag| tag.name == tagname }
  end

  private

  def copy_from_local(destination_dir)
    path_to_local_repo = File.join(@local_repo_dir, short_name)
    if File.exist?(path_to_local_repo)
      log '  copying '.yellow + path_to_local_repo
      FileUtils.cp_r path_to_local_repo, File.join(destination_dir, directory)
      true
    else
      log '  skipping (not found) '.magenta + path_to_local_repo
      false
    end
  end

  def copy_from_remote(destination_dir)
    output_dir = Dir.mktmpdir
    log '  downloading '.yellow + archive_link.blue

    response = Faraday.new.get(archive_link)
    raise "Unable to download repository #{@full_name}: server response #{response.status}" unless response.status == 200

    tarball_path = File.join(output_dir, "#{short_name}.tar.gz")
    File.open(tarball_path, 'w') { |f| f.write(response.body) }

    directory_listing_before = Dir.entries output_dir
    shell_out "tar xzf #{tarball_path} -C #{output_dir}"
    directory_listing_after = Dir.entries output_dir

    from = File.join output_dir, (directory_listing_after - directory_listing_before).first
    FileUtils.mv from, File.join(destination_dir, directory)

    true
  end

  def initialize(repo_hash, github_token, local_repo_dir, destination_dir)
    @github = GitClient.new(access_token: github_token) unless local_repo_dir

    @sha = repo_hash['sha']
    @full_name = repo_hash.fetch('github_repo')
    @directory = repo_hash['directory']
    @local_repo_dir = local_repo_dir
    @copied = copy_to(destination_dir) if destination_dir
    @subnav_template = repo_hash.fetch('subnav_template', 'default')
  end
end