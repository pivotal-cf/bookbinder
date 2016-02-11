require_relative '../../../lib/bookbinder/ingest/destination_directory'

module Bookbinder
  module Config
    class DitaConfigGenerator

      def initialize(section_hash)
        @section_hash = section_hash
      end

      def subnav_template
        dest_dir = Ingest::DestinationDirectory.new(section_hash.fetch('repository', {})['name'], section_hash['directory'])

        "dita_subnav_#{dest_dir}"
      end

      def ditamap_location
        section_hash['ditamap_location'] if section_hash['ditamap_location'] && !section_hash['ditamap_location'].empty?
      end

      def pdf_output_filename
        if present?(section_hash['output_filename'])
          filename = section_hash['output_filename']
        elsif ditamap_location
          filename =  ditamap_location.gsub(/\.ditamap/, '')
        else
          return
        end

        filename + '.pdf'
      end

      def preprocessor_config
        {
          'preprocessor_config' => {
            'ditamap_location' => ditamap_location,
            'ditaval_location' => section_hash['ditaval_location']
          }
        }
      end

      def to_hash
        section_hash.tap do |hash|
          hash.merge!(preprocessor_config)
              .merge!('subnav_template' => subnav_template, 'output_filename' => pdf_output_filename)

          hash.delete('ditaval_location')
          hash.delete('ditamap_location')
        end
      end

      private

      attr_reader :section_hash
      
      def present?(value)
        value && !value.empty?
      end
    end
  end
end
