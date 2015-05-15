require_relative '../ingest/destination_directory'

module Bookbinder
  Section = Struct.new(:path_to_repository,
                       :full_name,
                       :copied,
                       :destination_dir,
                       :directory_name,
                       :subnav_templ,
                       :preprocessor_config) do
    def requires_preprocessing?
      !preprocessor_config.nil?
    end

    def path_to_repository
      Pathname(self[:path_to_repository].to_s)
    end

    def subnav_template
      subnav_templ.sub(/^_/, '').sub(/\.erb$/, '') if subnav_templ
    end

    def directory
      Ingest::DestinationDirectory.new(full_name, directory_name)
    end

    def subnav
      namespace = directory.to_s.gsub('/', '_')
      template = subnav_template || 'default'
      {namespace => template}
    end

    def path_to_preprocessor_attribute(attr)
      path_to_repository.join(preprocessor_config[attr]) if preprocessor_config[attr]
    end
  end
end
