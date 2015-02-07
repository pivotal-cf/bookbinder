module Bookbinder
  class ArchiveDropDownMenu
    def initialize(config, current_path: nil)
      @config = config || default_config
      @current_path = current_path
    end

    def title
      directory_config.first
    end

    def dropdown_links
      versions_to_paths.map { |version_path|
        {version_path.keys.first => "/#{version_path.values.first}"}
      }
    end

    private

    attr_reader :config, :current_path

    def versions_to_paths
      directory_config[1..-1]
    end

    def directory_config
      config.fetch(directory, config.fetch(root_menu_reference)) || empty_menu
    end

    def directory
      File.dirname(current_path)
    end

    def default_config
      { root_menu_reference => empty_menu }
    end

    def empty_menu
      [nil]
    end

    def root_menu_reference
      '.'
    end
  end
end
