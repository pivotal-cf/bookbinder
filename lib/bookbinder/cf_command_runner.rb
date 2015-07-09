require_relative 'deploy/blue_green_app'

module Bookbinder
  class CfCommandRunner
    def initialize(streams, sheller, cf_credentials, trace_file)
      @streams = streams
      @sheller = sheller
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

      result = sheller.run_command(
        "#{cf_binary_path} login #{creds_string} -a '#{api_endpoint}' -o '#{organization}' -s '#{space}'",
        streams
      )
      raise "Could not log in to #{creds.api_endpoint}" unless result.success?
    end

    def cf_routes_output
      sheller.get_stdout("CF_COLOR=false #{cf_binary_path} routes").tap do |output|
        raise 'failure executing cf routes' if output == ''
      end
    end

    def new_app
      Deploy::BlueGreenApp.new([creds.app_name, 'blue'].join('-'))
    end

    def start(deploy_target_app)
      # Theoretically we shouldn't need this (and corresponding "stop" below), but we've seen CF pull files from both
      # green and blue when a DNS redirect points to HOST.cfapps.io
      # Also, shutting down the unused app saves $$
      sheller.run_command("#{cf_binary_path} start #{deploy_target_app}", streams)
    end

    def push(deploy_target_app)
      # Currently --no-routes is used to blow away all existing routes from a newly deployed app.
      # The routes will then be recreated from the creds repo.
      result = sheller.run_command(
        environment_variables,
        "#{cf_binary_path} push #{deploy_target_app} -s cflinuxfs2 --no-route -m 256M -i 3",
        streams
      )
      raise "Could not deploy app to #{deploy_target_app}" unless result.success?
    end

    def unmap_routes(app)
      creds.flat_routes.each do |domain, host|
        unmap_route(app, domain, host)
      end
    end

    def map_routes(app)
      succeeded = []

      creds.flat_routes.each do |domain, name|
        begin
          map_route(app, domain, name)
          succeeded << [app, domain, name]
        rescue RuntimeError
          succeeded.each { |app, domain, host| unmap_route(app, domain, host) }
          raise
        end
      end
    end

    def takedown_old_target_app(app)
      # Routers flush every 10 seconds (but not guaranteed), so wait a bit longer than that.
      streams[:out].puts "waiting 15 seconds for routes to remap...\n\n"
      (1..15).to_a.reverse.each do |seconds|
        streams[:out] << "\r\r#{seconds}...    "
        Kernel.sleep 1
      end
      stop(app)
      unmap_routes(app)
    end

    private

    attr_reader :creds, :sheller, :streams

    def stop(app)
      result = sheller.run_command("#{cf_binary_path} stop #{app}", streams)
      raise "Failed to stop application #{app}" unless result.success?
    end

    def map_route(deploy_target_app, domain, host)
      map_route_command = "#{cf_binary_path} map-route #{deploy_target_app} #{domain}"
      map_route_command += " -n #{host}" unless host.empty?

      result = sheller.run_command(map_route_command, streams)
      raise "Deployed app to #{deploy_target_app} but failed to map hostname #{host}.#{domain} to it." unless result.success?
    end

    def unmap_route(deploy_target_app, domain, host)
      unmap_route_command = "#{cf_binary_path} unmap-route #{deploy_target_app} #{domain}"
      unmap_route_command += " -n #{host}" unless host.empty?

      result = sheller.run_command(unmap_route_command, streams)
      raise "Failed to unmap route #{host} on #{deploy_target_app}." unless result.success?
    end

    def cf_binary_path
      @cf_binary_path ||= sheller.get_stdout("which cf").tap do |path|
        if path == ''
          raise "CF CLI could not be found in your PATH. Please make sure cf cli is in your PATH."
        end
      end
    end

    def environment_variables
      {'CF_TRACE' => @trace_file}
    end
  end
end
