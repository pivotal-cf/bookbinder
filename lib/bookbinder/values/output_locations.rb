require_relative '../directory_helpers'
require_relative '../errors/programmer_mistake'

module Bookbinder
  class OutputLocations
    include DirectoryHelperMethods

    def initialize(final_app_dir: nil, context_dir: nil)
      @final_app_dir = final_app_dir
      @context_dir = context_dir
    end

    def final_app_dir
      Pathname(@final_app_dir)
    end

    def public_dir
      final_app_dir.join('public')
    end

    def build_dir
      master_dir.join('build/.')
    end

    def workspace_dir
      master_dir.join('source')
    end

    def master_dir
      output_dir.join('master_middleman')
    end

    def output_dir
      context_dir.join(output_dir_name)
    end

    def preprocessing_home_dir
      output_dir.join('preprocessing')
    end

    def cloned_preprocessing_dir
      preprocessing_home_dir.join('sections')
    end

    def html_from_preprocessing_dir
      preprocessing_home_dir.join('html_from_preprocessing')
    end

    def pdf_from_preprocessing_dir
      preprocessing_home_dir.join('pdf_from_preprocessing')
    end

    def formatted_dir
      preprocessing_home_dir.join('site_generator_ready')
    end

    def site_generator_home
      output_dir.join('master_middleman')
    end

    def source_for_site_generator
      site_generator_home.join('source')
    end

    def subnavs_for_layout_dir
      source_for_site_generator.join('subnavs')
    end

    def pdf_config_dir
      context_dir
    end

    def artifact_dir
      context_dir.join('artifacts')
    end

    def pdf_artifact_dir
      artifact_dir.join('pdfs')
    end

    private

    def context_dir
      if @context_dir.nil?
        raise Errors::ProgrammerMistake.new("You must provide a context_dir to OutputLocations")
      else
        Pathname(@context_dir)
      end
    end
  end
end
