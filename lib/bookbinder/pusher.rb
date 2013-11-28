class Pusher

  def push(api_endpoint, host, organization, space, app_name, app_dir, username = nil, password = nil)
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''
    Dir.chdir(app_dir) do
      system "#{gcf_binary_path} login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'"

      # query which app (green/blue) the hostname currently points to
      first_routed_app_name_for_host = `CF_COLOR=false #{gcf_binary_path} routes | grep #{host}`.split(/,?\s+/)[2] || ""
      currently_deployed_to_green = first_routed_app_name_for_host.include? "green"

      deploy_target_app = "#{app_name}-#{currently_deployed_to_green ? "blue" : "green"}"
      deploy_old_target_app = "#{app_name}-#{currently_deployed_to_green ? "green" : "blue"}"

      # deploy to the other instance

      # Theoretically we shouldn't need this (and corresponding "stop" below), but we've seen CF pull files from both
      # green and blue when a DNS redirect points to HOST.cfapps.io
      # Also, shutting down the unused app saves $$
      system("#{gcf_binary_path} start #{deploy_target_app}")

      # --no-route is a hack that may need to be removed soon. Sheel can help.
      # it's a workaround for a bug in gcf that fails deployment for apps that have been deployed previously,
      # claiming that their hostname is already taken (instead of just re-deploying)
      if(system "#{gcf_binary_path} push #{deploy_target_app} --no-route -m '256' -i '2'")
        # map hostname to newly deployed app
        if(system("#{gcf_binary_path} map-route #{deploy_target_app} cfapps.io -n #{host}"))
          # unmap hostname from old deployed app.
          # Routers flush every 10 seconds (but not guaranteed), so wait a bit longer than that.
          puts "waiting 15 seconds for routes to remap...\n\n"
          (1..15).to_a.reverse.each do |seconds|
            print "\r#{seconds}...    "
            sleep 1
          end
          system("#{gcf_binary_path} stop #{deploy_old_target_app}")
          system("#{gcf_binary_path} unmap-route #{deploy_old_target_app} cfapps.io -n #{host}")
        else
          raise "Deployed app to #{deploy_target_app} but failed to map hostname #{host}.cfapps.io to it."
        end
      else
        raise "Could not deploy app to #{deploy_target_app}"
      end
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