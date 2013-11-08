class DocRepo

  include ShellOut
  include BookbinderLogger


  attr_reader :full_name, :sha

  def self.head_sha_for(full_name, github_username, github_password)
    party_options = {basic_auth: {username: github_username, password: github_password}}
    response = HTTParty.get(github_master_head_ref_url(full_name), party_options)
    # TODO: throw a useful error if this fails (could be either a bad repo name or bad auth)
    result = JSON.parse(response.body)
    result['object']['sha']
  end

  def self.github_master_head_ref_url(full_name)
    "https://api.github.com/repos/#{full_name}/git/refs/heads/master"
  end

  def initialize(repo_hash, github_username, github_password, local_repo_dir)
    if repo_hash['sha'].nil? && !local_repo_dir
      repo_hash['sha'] = DocRepo.head_sha_for repo_hash['github_repo'],
                                              github_username,
                                              github_password
    end
    @full_name = repo_hash['github_repo']
    @sha = repo_hash['sha']
    @directory = repo_hash['directory']
    @local_repo_dir = local_repo_dir
  end

  def github_tarball_url
    "https://github.com/#{full_name}/archive/#{sha}.tar.gz"
  end

  def directory
    @directory ? @directory : name
  end

  def name
    @full_name.split('/')[1]
  end

  def copy_to(destination_dir)
    if @local_repo_dir.nil?
      output_dir = Dir.mktmpdir
      log '  downloading '.yellow + github_tarball_url
      response = HTTParty.get(github_tarball_url)
      # TODO handle an invalid response caused by user entering an invalid sha or pointing to a password protected repo
      downloaded_tarball_path = File.join(output_dir, "#{name}.tar.gz")
      File.open(downloaded_tarball_path, 'w') { |f| f.write(response.body) }

      shell_out "tar xzf #{downloaded_tarball_path} -C #{output_dir}"

      from = File.join output_dir, "#{name}-#{sha}"
      FileUtils.mv from, File.join(destination_dir, directory)
    else
      path_to_local_repo = File.join(@local_repo_dir, name)
      if File.exist?(path_to_local_repo)
        log '  copying '.yellow + path_to_local_repo
        FileUtils.cp_r path_to_local_repo, File.join(destination_dir, directory)
      else
        log '  skipping (not found) '.magenta + path_to_local_repo
      end
    end
  end
end