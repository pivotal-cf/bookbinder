module Bookbinder
  class CfRoutes
    def initialize(raw_routes)
      @raw_routes = raw_routes
    end

    def apps_by_host_and_domain
      @apps_by_host_and_domain ||= Hash[
          raw_routes.lines[3..-1].
              map { |line| line.split(/\s+/, 4) }.
              map { |item| [item[1..2], item[3].split(',').map(&:strip)] }
      ]
    end

    private

    attr_reader :raw_routes
  end
end