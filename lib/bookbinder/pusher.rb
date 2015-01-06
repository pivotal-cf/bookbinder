require_relative 'cf_app_fetcher'

module Bookbinder
  class Pusher
    def initialize(cf_cli, app_fetcher)
      @cf_cli = cf_cli
      @app_fetcher = app_fetcher
    end

    def push(app_dir)
      Dir.chdir(app_dir) do
        cf_cli.login

        old_app = app_fetcher.fetch_current_app

        if old_app
          new_app = old_app.with_flipped_name
          cf_cli.start(new_app)
          cf_cli.push(new_app)
          cf_cli.map_routes(new_app)
          cf_cli.takedown_old_target_app(old_app)
        else
          new_app = cf_cli.new_app
          cf_cli.push(new_app)
          cf_cli.map_routes(new_app)
        end
      end
    end

    private

    attr_reader :cf_cli, :app_fetcher
  end
end
