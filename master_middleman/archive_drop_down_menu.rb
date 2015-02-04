module Bookbinder
  class ArchiveDropDownMenu
    def initialize(config)
      @current_version, *@versions_to_paths = config
    end

    def title
      current_version
    end

    def dropdown_links
      versions_to_full_paths
    end

    private

    attr_reader :current_version, :versions_to_paths

    def versions_to_full_paths
      versions_to_paths.map { |version_path|
        {version_path.keys.first => "/#{version_path.values.first}"}
      }
    end
  end
end
