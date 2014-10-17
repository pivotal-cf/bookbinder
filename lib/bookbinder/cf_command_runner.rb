require 'open3'

class CfCommandRunner
  attr_reader :creds

  def initialize(logger, cf_credentials, trace_file)
    @logger = logger
    @creds = cf_credentials
    @trace_file = trace_file
  end

  def login
    username = creds.username
    password = creds.password
    api_endpoint = creds.api_endpoint
    organization = creds.organization
    space = creds.space
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''

    success = Kernel.system("#{cf_binary_path} login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'")
    raise "Could not log in to #{creds.api_endpoint}" unless success
  end

  def apps
    # NB -- this function may not function as intended (the CLI's `cf apps`): it is intended to tell us whether Blue or Green is running,
    # but if it queries both apps and has route overlaps (e.g., docs.pivotal.io is on Blue and Green), it may not serve the purpose intended (see Pusher.rb line 12)
    hosts.map { |host| apps_for_host(host) }
  end

  def apps_for_host(host)
    # created this from what used to be #apps to deal with adding multiple hostnames in creds.host
    output, status = Open3.capture2("CF_COLOR=false #{cf_binary_path} routes")
    raise 'failure executing cf routes' unless status.success?


    # this fails if there is a new route in the creds that has not been mapped before. need to see if this is ok
    route = output.lines.grep(/^#{Regexp.escape(host)}\s+cfapps\.io\s+/)[0]
    raise 'no routes found' if route.nil?
    match = /cfapps\.io\s+(.+)$/.match(route.rstrip)
    raise 'no apps found' if match.nil?
    match[1].split(', ')
  end

  def start(deploy_target_app)
    # Theoretically we shouldn't need this (and corresponding "stop" below), but we've seen CF pull files from both
    # green and blue when a DNS redirect points to HOST.cfapps.io
    # Also, shutting down the unused app saves $$
    Kernel.system("#{cf_binary_path} start #{deploy_target_app} ")
  end

  def push(deploy_target_app)
    # --no-route is a hack that may need to be removed soon. Sheel can help.
    # it's a workaround for a bug in cf that fails deployment for apps that have been deployed previously,
    # claiming that their hostname is already taken (instead of just re-deploying)
    success = Kernel.system(environment_variables, "#{cf_binary_path} push #{deploy_target_app} --no-route -m 256M -i 2")
    raise "Could not deploy app to #{deploy_target_app}" unless success
  end

  def environment_variables
    {'CF_TRACE' => @trace_file}
  end

  def unmap_routes(app)
    hosts.map { |host| unmap_route(app, host) }
  end

  def map_routes(app)
    hosts.map { |host| map_route(app, host) }
  end

  def takedown_old_target_app(app)
    # unmap hostname from old deployed app.
    # Routers flush every 10 seconds (but not guaranteed), so wait a bit longer than that.
    @logger.log "waiting 15 seconds for routes to remap...\n\n"
    (1..15).to_a.reverse.each do |seconds|
      @logger.log_print "\r\r#{seconds}...    "
      Kernel.sleep 1
    end
    stop(app)
    unmap_routes(app)
  end

  private

  def hosts
    Array(creds.host)
  end

  def stop(app)
    success = Kernel.system("#{cf_binary_path} stop #{app}")
    raise "Failed to stop application #{app}" unless success
  end

  def map_route(deploy_target_app, host)
    success = Kernel.system("#{cf_binary_path} map-route #{deploy_target_app} cfapps.io -n #{host}")
    raise "Deployed app to #{deploy_target_app} but failed to map hostname #{host}.cfapps.io to it." unless success
  end

  def unmap_route(app, host)
    success = Kernel.system("#{cf_binary_path} unmap-route #{app} cfapps.io -n #{host}")
    raise "Failed to unmap route #{app} on #{host}." unless success
  end

  def cf_binary_path
    @cf_binary_path ||= `which cf`.chomp!
    raise  "CF CLI could not be found in your PATH. Please make sure cf cli is in your PATH." if @cf_binary_path.nil?
    @cf_binary_path
  end
end
