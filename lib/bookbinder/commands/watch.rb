require_relative 'bind/bind_options'
require_relative 'naming'

module Bookbinder
  module Commands
    class Watch
      include Commands::Naming

      def initialize(streams,
                     middleman_runner: nil,
                     output_locations: nil,
                     config_fetcher: nil,
                     config_decorator: nil,
                     file_system_accessor: nil,
                     preprocessor: nil,
                     cloner: nil,
                     section_repository: nil,
                     directory_preparer: nil)
        @streams = streams
        @middleman_runner = middleman_runner
        @output_locations = output_locations
        @config_fetcher = config_fetcher
        @config_decorator = config_decorator
        @file_system_accessor = file_system_accessor
        @preprocessor = preprocessor
        @cloner = cloner
        @section_repository = section_repository
        @directory_preparer = directory_preparer
      end

      def usage
        ["watch",
         "Bind and serve a local book, watching for changes"]
      end

      def run(_)
        watch_config = config_fetcher.fetch_config

        directory_preparer.prepare_directories(
          watch_config,
          File.expand_path('../../../../', __FILE__),
          output_locations,
          cloner
        )
        sections = section_repository.fetch(
          configured_sections: watch_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          cloner: cloner,
          streams: streams
        )
        preprocessor.preprocess(
          sections,
          output_locations,
          output_streams: streams,
          config: watch_config
        )
        if file_system_accessor.file_exist?('redirects.rb')
          file_system_accessor.copy('redirects.rb', output_locations.final_app_dir)
        end

        middleman_runner.run("server --force-polling --latency=5.0",
          output_locations: output_locations,
          config: config_decorator.generate(watch_config, sections),
          local_repo_dir: File.expand_path('..'),
          streams: streams,
          subnavs: subnavs(sections)
        ).exitstatus
      end

      private

      attr_reader(
        :streams,
        :middleman_runner,
        :output_locations,
        :config_fetcher,
        :config_decorator,
        :file_system_accessor,
        :preprocessor,
        :cloner,
        :section_repository,
        :directory_preparer
      )

      def subnavs(sections)
        sections.map(&:subnav).reduce({}, :merge)
      end

    end
  end
end
