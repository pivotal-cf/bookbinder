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
    output, status = Open3.capture2("CF_COLOR=false #{cf_binary_path} routes")
    raise 'failure executing cf routes' unless status.success?
    route = output.lines.grep(/^#{Regexp.escape(creds.host)}\s+cfapps\.io\s+/)[0]
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

  def map_route(deploy_target_app)
    # map hostname to newly deployed app
    success = Kernel.system("#{cf_binary_path} map-route #{deploy_target_app} cfapps.io -n #{creds.host}")
    raise "Deployed app to #{deploy_target_app} but failed to map hostname #{creds.host}.cfapps.io to it." unless success
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
    unmap_route(app, creds.host)
  end

  private

  def stop(app)
    success = Kernel.system("#{cf_binary_path} stop #{app}")
    raise "Failed to stop application #{app}" unless success
  end

  def unmap_route(app, host)
    success = Kernel.system("#{cf_binary_path} unmap-route #{app} cfapps.io -n #{host}")
    raise "Failed to unmap route #{app} on #{host}" unless success
  end

  def cf_binary_path
    # Assuming cf cli is installed correctly
    @cf_binary_path ||= '/usr/local/bin/cf'
    raise  "CF CLI could not be found in /usr/local/bin. Please make sure your cf cli is installed correctly." unless File.exists? @cf_binary_path
    @cf_binary_path
  end
end
