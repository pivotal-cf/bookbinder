require_relative '../deprecated_logger'
require_relative '../ingest/destination_directory'
require_relative 'naming'

module Bookbinder
  module Commands
    class UpdateLocalDocRepos
      include Commands::Naming

      def initialize(streams, configuration_fetcher, version_control_system, filesystem)
        @streams = streams
        @configuration_fetcher = configuration_fetcher
        @version_control_system = version_control_system
        @filesystem = filesystem
      end

      def usage
        [command_name,
         "Run `git pull` on all sections that exist at the same directory level as your book directory"]
      end

      def run(_)
        urls = configuration_fetcher.fetch_config.sections.map(&:repo_url)
        paths(urls).each do |path|
          if filesystem.file_exist?(path)
            streams[:success].puts "Updating #{path}"
            version_control_system.update(path)
          else
            streams[:out].puts "  skipping (not found) #{path}"
          end
        end
        0
      end

      private

      attr_reader(:streams,
                  :configuration_fetcher,
                  :version_control_system,
                  :filesystem)

      def paths(urls)
        urls.map {|url| File.absolute_path("../#{Ingest::DestinationDirectory.new(url)}")}
      end
    end
  end
end
