class Pusher
  def push(api_endpoint, host, organization, space, app_name, app_dir='./final_app', username = nil, password = nil)
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''
    Dir.chdir(app_dir) do
      result = Kernel::system "#{cf_binary_path} login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'"
      raise "Could not log in to #{api_endpoint}" unless result

      # query which app (green/blue) the hostname currently points to
      first_routed_app_name_for_host = `CF_COLOR=false #{cf_binary_path} routes | grep #{host}`.split(/,?\s+/)[2] || ""
      currently_deployed_to_green = first_routed_app_name_for_host.include? "green"

      new_app = "#{app_name}-#{currently_deployed_to_green ? "blue" : "green"}"
      old_app = "#{app_name}-#{currently_deployed_to_green ? "green" : "blue"}"

      # deploy to the other instance
      cf_start(new_app)

      raise push_failure_msg(new_app) unless cf_push(new_app)
      raise map_failure_msg(new_app, host) unless cf_map_route(new_app, host)
      takedown_old_target_app(old_app, host)
    end
  end

  private

  def push_failure_msg(deploy_target_app)
    "Could not deploy app to #{deploy_target_app}"
  end

  def map_failure_msg(deploy_target_app, host)
    "Deployed app to #{deploy_target_app} but failed to map hostname #{host}.cfapps.io to it."
  end

  def takedown_old_target_app(app, host)
    # unmap hostname from old deployed app.
    # Routers flush every 10 seconds (but not guaranteed), so wait a bit longer than that.
    puts "waiting 15 seconds for routes to remap...\n\n"
    (1..15).to_a.reverse.each do |seconds|
      print "\r#{seconds}...    "
      sleep 1
    end
    cf_stop(app)
    cf_unmap_route(app, host)
  end

  def cf_unmap_route(app, host)
    Open4::popen4("#{cf_binary_path} unmap-route #{app} cfapps.io -n #{host}")
  end

  def cf_stop(app)
    Open4::popen4("#{cf_binary_path} stop #{app}")
  end

  def cf_start(deploy_target_app)
    # Theoretically we shouldn't need this (and corresponding "stop" below), but we've seen CF pull files from both
    # green and blue when a DNS redirect points to HOST.cfapps.io
    # Also, shutting down the unused app saves $$
    Open4::popen4("#{cf_binary_path} start #{deploy_target_app}")
  end

  def cf_map_route(deploy_target_app, host)
    # map hostname to newly deployed app
    Open4::popen4("#{cf_binary_path} map-route #{deploy_target_app} cfapps.io -n #{host}")
  end

  def cf_push(deploy_target_app)
    # --no-route is a hack that may need to be removed soon. Sheel can help.
    # it's a workaround for a bug in cf that fails deployment for apps that have been deployed previously,
    # claiming that their hostname is already taken (instead of just re-deploying)
    Open4::popen4("#{cf_binary_path} push #{deploy_target_app} --no-route -m 256M -i 2")
  end

  def cf_binary_path
    @cf_binary_path ||= File.join(GEM_ROOT, 'bin', `uname`.downcase.strip, 'cf')
  end
end
