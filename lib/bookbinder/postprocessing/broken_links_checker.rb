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

      def check!(broken_link_exclusions)
        server_director.use_server { |port|
          @result = spider.find_broken_links(port, broken_link_exclusions: broken_link_exclusions)
        }
      end

      def announce(streams)
        @result.announce_broken_links(streams)
      end

      def has_broken_links?
        @result.has_broken_links?
      end

      private

      attr_reader :server_director, :spider
    end
  end
end
