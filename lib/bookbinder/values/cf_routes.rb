module Bookbinder
  class CfRoutes
    def initialize(raw_routes)
      @raw_routes = raw_routes
    end

    def apps_by_host_and_domain
      @apps_by_host_and_domain ||= data(raw_routes).reduce({}) {|acc, row|
        parsed_row = Hash[headers(raw_routes).zip(row)]
        acc.merge(parsed_row.values_at('host', 'domain') => parse_apps(parsed_row['apps']))
      }
    end

    private

    attr_reader :raw_routes

    def parse_apps(apps)
      apps.split(',').map(&:strip)
    end

    def headers(raw)
      raw.lines[2].split(/\s+/)
    end

    def data(raw)
      raw.lines[3..-1].map {|line| line.split(/\s+/, headers(raw).size)}
    end
  end
end
