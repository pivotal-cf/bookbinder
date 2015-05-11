module Bookbinder
  class ArchiveMenuConfiguration
    def initialize(loader: nil, config_filename: nil)
      @loader = loader
      @config_filename = config_filename
    end

    def generate(base_config, sections)
      base_config.merge(
        Configuration.new(
          'archive_menu' => root_config(base_config).merge(section_config(sections))))
    end

    private

    attr_reader :loader, :config_filename

    def root_config(base_config)
      { '.' => base_config.archive_menu }
    end

    def section_config(sections)
      sections.reduce({}) {|config, section|
        config_path = section.path_to_repository.join(config_filename)
        archive_config = loader.load_key(config_path, 'archive_menu')
        if archive_config
          config.merge(section.directory_name => archive_config)
        else
          config
        end
      }
    end
  end
end
