require_relative 'configuration'

module Bookbinder
  module Config
    class ConfigurationDecorator
      def initialize(loader: nil, config_filename: nil)
        @loader = loader
        @config_filename = config_filename
      end

      def generate(base_config, sections)
        base_config.merge(
          Configuration.new(
            dir_repo_links: dir_repo_link_config(base_config, sections),
            archive_menu: root_config(base_config).merge(section_config(sections)))
        )
      end

      private

      attr_reader :loader, :config_filename

      def dir_repo_link_config(base_config, sections)
        if base_config.dir_repo_link_enabled
          sections.reduce({}) {|config, section|
            [config.merge(section.desired_directory_name => section.path_to_repo_dir.to_s)]
          }
        end
      end

      def root_config(base_config)
        { '.' => base_config.archive_menu }
      end

      def section_config(sections)
        sections.reduce({}) {|config, section|
          config_path = section.path_to_repo_dir.join(config_filename)
          archive_config = loader.load_key(config_path, 'archive_menu')
          if archive_config
            config.merge(section.desired_directory_name => archive_config)
          else
            config
          end
        }
      end
    end
  end
end
