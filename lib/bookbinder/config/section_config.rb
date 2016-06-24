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

      def product_id
        config['product_id']
      end

      def desired_directory_name
        config['directory']
      end

      def pdf_output_filename
        config['output_filename']
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

      def at_repo_path
        repo['at_path']
      end

      def no_docs?
        config.fetch('no_docs', false)
      end

      def dependent_sections
        @sections ||= (config['dependent_sections'] || []).map do |dep_section|
          SectionConfig.new(dep_section)
        end
      end

      def preprocessor_config
        config.fetch('preprocessor_config', {})
      end

      def ==(other)
        config == other.instance_variable_get(:@config)
      end

      def merge(other_section_config)
        SectionConfig.new(config.merge(other_section_config.instance_variable_get(:@config)))
      end

      def inspect
        config.inspect
      end

      alias_method :subnav_name, :product_id

      def product_info
        return {} if config['product_info'].nil?
        config['product_info']
      end

      private

      def repo
        config.fetch('repository', {})
      end

      attr_reader :config
    end
  end
end

