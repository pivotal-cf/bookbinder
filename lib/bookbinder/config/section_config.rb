require_relative '../ingest/repo_identifier'

module Bookbinder
  module Config
    class SectionConfig
      def initialize(config)
        @config = config
      end

      def subnav_template
        config['subnav_template']
      end

      def desired_directory_name
        config['directory']
      end

      def repo_name
        repo['name']
      end

      def repo_url
        Ingest::RepoIdentifier.new(repo['name'])
      end

      def repo_ref
        repo['ref'] || 'master'
      end

      def ==(other)
        config == other.instance_variable_get(:@config)
      end

      private

      def repo
        config['repository']
      end

      attr_reader :config
    end
  end
end

