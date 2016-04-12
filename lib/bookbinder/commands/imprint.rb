require_relative 'components/command_options'

module Bookbinder
  module Commands
    class Imprint
      def initialize(base_streams,
                     output_locations: nil,
                     config_fetcher: nil,
                     preprocessor: nil,
                     cloner_factory: nil,
                     section_repository: nil,
                     directory_preparer: nil)

        @base_streams = base_streams
        @output_locations = output_locations
        @config_fetcher = config_fetcher
        @preprocessor = preprocessor
        @cloner_factory = cloner_factory
        @section_repository = section_repository
        @directory_preparer = directory_preparer
      end

      def run(bind_type, verbose = false, dita_flags = nil)
        options        = Components::CommandOptions.new([bind_type], base_streams, verbose)
        config         = config_fetcher.fetch_config
        cloner         = cloner_factory.produce(options.local_repo_dir)

        directory_preparer.prepare_directories(output_locations)

        sections = section_repository.fetch(
          configured_sections: config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: options.ref_override,
          cloner: cloner,
          streams: base_streams
        )

        preprocessor.preprocess(
          sections,
          output_locations,
          options: { dita_flags: dita_flags },
          output_streams: options.streams,
          config: config
        )

        options.streams[:success].puts "Bookbinder printed your pdf(s) into #{output_locations.pdf_artifact_dir}"
        0
      end

      private

      attr_reader :preprocessor, :output_locations, :section_repository, :base_streams, :config_fetcher, :directory_preparer, :cloner_factory
    end
  end
end
