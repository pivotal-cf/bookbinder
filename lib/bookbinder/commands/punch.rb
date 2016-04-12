module Bookbinder
  module Commands
    class Punch
      def initialize(streams, configuration_fetcher, version_control_system)
        @streams = streams
        @configuration_fetcher = configuration_fetcher
        @version_control_system = version_control_system
      end

      def run((tag, *))
        urls(config).each do |url|
          version_control_system.remote_tag(url, tag, 'HEAD')
        end

        streams[:success].puts 'Success!'
        streams[:out].puts "#{config.book_repo} and its sections were tagged with #{tag}"
        0
      end

      private

      attr_reader :streams, :configuration_fetcher, :version_control_system

      def urls(config)
        [config.book_repo_url, config.layout_repo_url] + config.sections.map(&:repo_url).uniq
      end

      def config
        @config ||= configuration_fetcher.fetch_config
      end
    end
  end
end
