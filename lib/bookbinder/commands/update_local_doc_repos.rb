require_relative '../ingest/destination_directory'
require_relative 'naming'

module Bookbinder
  module Commands
    class UpdateLocalDocRepos
      include Commands::Naming

      def initialize(streams, configuration_fetcher, version_control_system)
        @streams = streams
        @configuration_fetcher = configuration_fetcher
        @version_control_system = version_control_system
      end

      def usage
        [command_name,
         "Run `git pull` on all sections that exist at the same directory level as your book directory"]
      end

      def run(_)
        urls = configuration_fetcher.fetch_config.sections.map(&:repo_url)
        paths(urls).each do |path|
          streams[:out] << "\nUpdating #{path}:"
          report(version_control_system.update(path))
        end
        streams[:out].puts
        0
      end

      private

      attr_reader(:streams,
                  :configuration_fetcher,
                  :version_control_system)

      def report(result)
        messages = { true => "updated", false => "skipping (#{result.reason})" }
        streams[stream_types[result.success?]] << " #{messages[result.success?]}"
      end

      def stream_types
        { true => :success, false => :out }
      end

      def paths(urls)
        urls.map {|url| File.absolute_path("../#{Ingest::DestinationDirectory.new(url)}")}
      end
    end
  end
end
