require_relative '../ingest/destination_directory'

module Bookbinder
  module Commands
    class UpdateLocalDocRepos
      def initialize(streams, configuration_fetcher, version_control_system)
        @streams = streams
        @configuration_fetcher = configuration_fetcher
        @version_control_system = version_control_system
      end

      def run
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
