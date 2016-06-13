module Bookbinder
  module Commands
    class Watch
      def initialize(streams,
                     middleman_runner: nil,
                     output_locations: nil,
                     config_fetcher: nil,
                     config_decorator: nil,
                     file_system_accessor: nil,
                     preprocessor: nil,
                     cloner: nil,
                     section_repository: nil,
                     directory_preparer: nil,
                     repo_restrictions: [])
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
        @repo_restrictions = repo_restrictions
      end

      def run
        watch_config = config_fetcher.fetch_config

        directory_preparer.prepare_directories(
          watch_config,
          File.expand_path('../../../../', __FILE__),
          output_locations,
          cloner
        )
        sections = section_repository.fetch(
          configured_sections: filter_sections(watch_config.sections),
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
          subnavs: subnavs(sections),
          product_info: product_infos(sections)
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

      def product_infos(sections)
        temp = Hash.new
        sections.each do |section|
          temp[section.namespace] = section.product_info
        end
        temp
      end

      def filter_sections(section_configs)
        return section_configs if @repo_restrictions.nil? || @repo_restrictions.empty?

        section_configs.select do |config|
          repo_name = (config.repo_name || '').split('/').last
          @repo_restrictions.include?(repo_name)
        end
      end
    end
  end
end
