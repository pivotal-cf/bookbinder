class Pusher

  def push(api_endpoint, organization, space, app_name, app_dir, username = nil, password = nil)
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''
    Dir.chdir(app_dir) do
      system "#{gcf_binary_path} login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'"
      system "#{gcf_binary_path} push #{app_name} --no-route"
      # --no-route is a hack that may need to be removed soon. Sheel can help.
      # it's a workaround for a bug in gcf that fails deployment for apps that have been deployed previously,
      # claiming that their hostname is already taken (instead of just re-deploying)
    end
  end

  def gcf_binary_path
    @gcf_binary_path ||= get_gcf_binary_path
  end

  def get_gcf_binary_path
    spec = Gem::Specification.find_by_name('bookbinder')
    gem_root = spec.gem_dir
    arch = `uname`.downcase.strip
    File.join(gem_root, 'bin', arch, 'gcf')
  end
end