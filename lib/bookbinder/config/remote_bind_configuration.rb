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
        base_config.merge_sections(base_config.versions.flat_map { |version| sections_from(version) })
      end

      private

      attr_reader :version_control_system, :base_config

      def sections_from(version)
        sections = Configuration.parse(
          YAML.load(
          version_control_system.read_file(
            'config.yml',
            from_repo: base_config.book_repo_url,
            checkout: version
          )
        )).sections
        raise VersionUnsupportedError.new(version) if sections.empty?

        sections.map do |section|
          section.merge(
            Config::SectionConfig.new(
              'repository' => { 'name' => section.repo_name, 'ref' => version },
              'directory' => File.join(version, section.desired_directory_name)
            )
          )
        end
      end
    end
  end
end
