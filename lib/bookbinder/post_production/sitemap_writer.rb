require_relative '../server_director'
require_relative '../spider'

module Bookbinder
  module PostProduction
    class SitemapWriter
      def self.build(logger, final_app_directory, port)
        new(
          Spider.new(app_dir: final_app_directory),
          ServerDirector.new(directory: final_app_directory, port: port)
        )
      end

      def initialize(spider, server_director)
        @spider = spider
        @server_director = server_director
      end

      def write(host_for_sitemap, streams, broken_link_exclusions)
        server_director.use_server { |port|
          spider.generate_sitemap(
            host_for_sitemap,
            port,
            streams,
            broken_link_exclusions: broken_link_exclusions
          )
        }.tap do |sitemap|
          File.write(sitemap.to_path, sitemap.to_xml)
        end
      end

      private

      attr_reader :server_director, :spider
    end
  end
end
