module Bookbinder
  class Pusher
    def initialize(cf_cli)
      @cf_cli = cf_cli
    end

    def push(app_dir)
      Dir.chdir(app_dir) do
        cf_cli.login

        old_app = cf_cli.apps.first.first
        currently_deployed_to_green = old_app.include? "green"

        new_app = "#{cf_cli.creds.app_name}-#{currently_deployed_to_green ? "blue" : "green"}"

        cf_cli.start(new_app)
        cf_cli.push(new_app)
        cf_cli.map_routes(new_app)
        cf_cli.takedown_old_target_app(old_app)
      end
    end

    private

    attr_reader :cf_cli
  end
end