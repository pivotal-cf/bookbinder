require_relative '../errors/programmer_mistake'
require_relative '../ingest/destination_directory'

module Bookbinder
  Section = Struct.new(:path_to_repository,
                       :full_name,
                       :desired_directory_name,
                       :subnav_templ,
                       :subnav_name,
                       :preprocessor_config) do
    def path_to_repository
      Pathname(self[:path_to_repository].to_s)
    end

    def subnav_template
      subnav_templ.sub(/^_/, '').sub(/\.erb$/, '') if subnav_templ
    end

    def destination_directory
      Ingest::DestinationDirectory.new(full_name, desired_directory_name)
    end

    def subnav
      namespace = destination_directory.to_s.gsub('/', '_')
      template = subnav_template || subnav_name || 'default'
      {namespace => template}
    end

    def path_to_preprocessor_attribute(attr)
      path_to_repository.join(preprocessor_config[attr]) if preprocessor_config[attr]
    rescue NoMethodError => e
      raise Errors::ProgrammerMistake.new(
        "path_to_preprocessor_attribute assumes preprocessor_config is available, got nil.\n" +
        "Original exception:\n\n#{e.inspect}\n\n#{e.backtrace.join("\n")}"
      )
    end
  end
end
