require 'yaml'
require_relative '../ingest/destination_directory'

module Bookbinder
  module Config
    class RemoteBindConfiguration
      VersionUnsupportedError = Class.new(RuntimeError)

      def initialize(version_control_system, base_config)
        @version_control_system = version_control_system
        @base_config = base_config
      end

      def fetch
        base_config.merge(
          'sections' => base_config.sections + base_config.versions.flat_map { |version| sections_from(version) },
          'book_repo' => base_config.book_repo,
          'public_host' => base_config.public_host,
          'archive_menu' => base_config.archive_menu,
          'versions' => base_config.versions,
          'template_variables' => base_config.template_variables
        )
      end

      private

      attr_reader :version_control_system, :base_config

      def sections_from(version)
        attrs = YAML.load(
          version_control_system.read_file(
            'config.yml',
            from_repo: "git@github.com:#{base_config.book_repo}",
            checkout: version
          )
        )['sections']
        raise VersionUnsupportedError.new(version) if attrs.nil?

        attrs.map do |section_hash|
          section_hash.merge(
            'repository' => section_hash['repository'].merge('ref' => version),
            'directory' => File.join(version, section_hash['directory'])
          )
        end
      end
    end
  end
end
