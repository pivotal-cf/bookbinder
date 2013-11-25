class DocRepo

  include ShellOut
  include BookbinderLogger


  attr_reader :full_name, :sha

  def self.head_sha_for(full_name, github_username, github_password)
    conn = Faraday.new(url: "https://api.github.com")
    conn.basic_auth(github_username, github_password)
    response = conn.get(github_master_head_ref_path(full_name))
    result = JSON.parse(response.body)
    if response.status != 200
      raise "Github API error: #{result['message']}"
    else
      result['object']['sha']
    end
  end

  def self.github_master_head_ref_path(full_name)
    "repos/#{full_name}/git/refs/heads/master"
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

  def github_tarball_path
    "#{full_name}/archive/#{sha}.tar.gz"
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
      log '  downloading '.yellow + "https://github.com/#{github_tarball_path}"
      conn = Faraday.new(url: "https://github.com") do |builder|
        builder.use FaradayMiddleware::FollowRedirects, limit: 5
        builder.adapter Faraday.default_adapter
      end
      response = conn.get(github_tarball_path)
      if response.status != 200
        raise 'Bad API Request. Check to make sure your sha is valid and the repo is not password protected'
      end
      downloaded_tarball_path = File.join(output_dir, "#{name}.tar.gz")
      File.open(downloaded_tarball_path, 'w') { |f| f.write(response.body) }

      shell_out "tar xzf #{downloaded_tarball_path} -C #{output_dir}"

      from = File.join output_dir, "#{name}-#{sha}"
      FileUtils.mv from, File.join(destination_dir, directory)
      true
    else
      path_to_local_repo = File.join(@local_repo_dir, name)
      if File.exist?(path_to_local_repo)
        log '  copying '.yellow + path_to_local_repo
        FileUtils.cp_r path_to_local_repo, File.join(destination_dir, directory)
        true
      else
        log '  skipping (not found) '.magenta + path_to_local_repo
        false
      end
    end
  end
end