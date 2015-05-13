require_relative '../deprecated_logger'
require_relative '../errors/cli_error'
require_relative 'naming'

module Bookbinder
  module Commands
    class Tag
      include Commands::Naming

      def initialize(logger, configuration_fetcher, version_control_system)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @version_control_system = version_control_system
      end

      def usage
        ["tag <git tag>", "Apply the specified <git tag> to your book and all sections of your book"]
      end

      def run((tag, *))
        raise CliError::InvalidArguments unless tag

        urls(config).each do |url|
          version_control_system.remote_tag(url, tag, 'HEAD')
        end

        @logger.log 'Success!'.green
        @logger.log " #{config.book_repo.yellow} and its sections were tagged with #{tag.blue}"
        0
      end

      private

      attr_reader :configuration_fetcher, :version_control_system

      def urls(config)
        [config.book_repo_url] + config.sections.map {|section| section['repo_url']}.uniq
      end

      def config
        @config ||= configuration_fetcher.fetch_config
      end
    end
  end
end
