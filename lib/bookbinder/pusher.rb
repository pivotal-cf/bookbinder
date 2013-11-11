class Pusher

  def push(api_endpoint, organization, space, app_name, app_dir, username = nil, password = nil)
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''
    Dir.chdir(app_dir) do
      system "~/bin/go-cf login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'"
      system "~/bin/go-cf push #{app_name}"
    end
  end

end