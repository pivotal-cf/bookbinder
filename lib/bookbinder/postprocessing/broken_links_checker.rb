require_relative '../server_director'
require_relative '../spider'
require_relative '../../../template_app/rack_app'

module Bookbinder
  module Postprocessing
    class BrokenLinksChecker
      def self.build(final_app_directory, port)
        new(
          Spider.new(app_dir: final_app_directory),
          ServerDirector.new(
            app: RackApp.new(Pathname('redirects.rb'), auth_required: false).app,
            directory: final_app_directory,
            port: port
          )
        )
      end

      def initialize(spider, server_director)
        @spider = spider
        @server_director = server_director
      end

      def find_broken_links(broken_link_exclusions)
        server_director.use_server { |port|
          spider.find_broken_links(port, broken_link_exclusions: broken_link_exclusions)
        }
      end

      private

      attr_reader :server_director, :spider
    end
  end
end
