require_relative '../errors/programmer_mistake'
require_relative '../ingest/destination_directory'

module Bookbinder
  Section = Struct.new(
    :path_to_repository,
    :full_name,
    :desired_directory_name,
    :subnav_templ,
    :desired_subnav_name,
    :preprocessor_config,
    :at_repo_path,
    :repo_name,
    :source_ref,
    :pdf_output_filename,
    :product_info) do

    def path_to_repo_dir
      at_repo_path.nil? ? path_to_repository : path_to_repository.join(at_repo_path)
    end

    def subnav_template
      subnav_templ.sub(/^_/, '').sub(/\.erb$/, '') if subnav_templ
    end

    def destination_directory
      Ingest::DestinationDirectory.new(full_name, desired_directory_name)
    end

    def subnav
      {namespace => subnav_name}
    end

    def namespace
      destination_directory.to_s.gsub(%r{[./]}, '_')
    end

    def subnav_name
      subnav_template || desired_subnav_name || 'default'
    end

    def path_to_preprocessor_attribute(attr)
      path_to_repo_dir.join(preprocessor_config[attr]) if preprocessor_config[attr]
    rescue NoMethodError => e
      raise Errors::ProgrammerMistake.new(
        "path_to_preprocessor_attribute assumes preprocessor_config is available, got nil.\n" +
          "Original exception:\n\n#{e.inspect}\n\n#{e.backtrace.join("\n")}"
      )
    end

    private

    def path_to_repository
      Pathname(self[:path_to_repository].to_s)
    end

  end
end
