require_relative '../server_director'
require_relative '../spider'

module Bookbinder
  module PostProduction
    class SitemapWriter
      def self.build(logger, final_app_directory)
        new(
          Spider.new(logger, app_dir: final_app_directory),
          ServerDirector.new(logger, directory: final_app_directory)
        )
      end

      def initialize(spider, server_director)
        @spider = spider
        @server_director = server_director
      end

      def write(host_for_sitemap)
        server_director.use_server { |port|
          spider.generate_sitemap host_for_sitemap, port
        }.tap do |sitemap|
          File.write(sitemap.to_path, sitemap.to_xml)
        end
      end

      private

      attr_reader :server_director, :spider
    end
  end
end
