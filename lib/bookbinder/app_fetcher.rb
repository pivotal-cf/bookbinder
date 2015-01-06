require_relative "blue_green_app"
require_relative "cf_routes"

module Bookbinder

  class AppFetcher
    def initialize(routes_to_search, cf_command_runner)
      @routes_to_search = routes_to_search
      @cf_command_runner = cf_command_runner
    end

    def fetch_current_app
      raw_cf_routes = cf_command_runner.cf_routes_output
      cf_routes = CfRoutes.new(raw_cf_routes)

      existing_hosts = routes_to_search.select do |domain, host|
        cf_routes.apps_by_host_and_domain.has_key?([host, domain])
      end

      app_groups =
          if existing_hosts.any?
            existing_hosts.map { |domain, host| apps_for_host(cf_routes, domain, host) }
          else
            raise "cannot find currently deployed app."
          end
      apps_for_existing_routes = app_groups.first
      apps_for_existing_routes.first
    end

    private

    attr_reader :routes_to_search, :cf_command_runner

    def apps_for_host(routes_from_cf, domain, host)
      routes_from_cf.apps_by_host_and_domain.fetch([host, domain], []).
          map &BlueGreenApp.method(:new)
    end
  end

end
