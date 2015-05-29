require 'yaml'
require 'ansi/code'

module Bookbinder
  module Config
    class RemoteYamlCredentialProvider
      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
      end

      def credentials(repo_url)
        logger.log "Processing #{ANSI.cyan{repo_url}}"
        YAML.load(version_control_system.read_file("credentials.yml", from_repo: repo_url))
      end

      private

      attr_reader :logger, :version_control_system
    end
  end
end
